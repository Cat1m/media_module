import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/media_item.dart';
import '../models/media_options.dart';
import '../utils/media_exceptions.dart';

/// Controller for handling media operations
class MediaController {
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  // Thêm một DeviceInfoPlugin duy nhất cho toàn controller
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Flag to prevent multiple concurrent cropImage calls
  bool _isCropping = false;

  /// Select media from gallery or camera
  Future<List<MediaItem>> pickMedia(MediaOptions options) async {
    try {
      // Check permissions
      if (options.source == MediaSource.camera) {
        final cameraPermission = await Permission.camera.request();
        if (cameraPermission.isDenied) {
          throw MediaPermissionException('Camera permission denied');
        }

        if (options.includeVideo) {
          final microphonePermission = await Permission.microphone.request();
          if (microphonePermission.isDenied) {
            throw MediaPermissionException('Microphone permission denied');
          }
        }
      } else {
        if (Platform.isAndroid) {
          // Kiểm tra phiên bản Android sử dụng sdkInt
          final androidInfo = await _deviceInfoPlugin.androidInfo;
          final sdkVersion = androidInfo.version.sdkInt;

          // Android 13 là API level 33
          if (sdkVersion >= 33) {
            // Android 13+: Kiểm tra READ_MEDIA_IMAGES
            final mediaImagesPermission = await Permission.photos.status;
            if (mediaImagesPermission.isDenied) {
              final requestResult = await Permission.photos.request();
              if (requestResult.isDenied) {
                throw MediaPermissionException(
                  'Media images permission denied',
                );
              }
            }
          } else {
            // Android <13: Kiểm tra READ_EXTERNAL_STORAGE
            final storagePermission = await Permission.storage.status;
            if (storagePermission.isDenied) {
              final requestResult = await Permission.storage.request();
              if (requestResult.isDenied) {
                throw MediaPermissionException('Storage permission denied');
              }
            }
          }
        } else if (Platform.isIOS) {
          // iOS: Kiểm tra quyền photos
          final photosPermission = await Permission.photos.status;
          if (photosPermission.isDenied) {
            final requestResult = await Permission.photos.request();
            if (requestResult.isDenied) {
              throw MediaPermissionException('Photos permission denied');
            }
          }
        }
      }

      // Pick media from selected source
      if (options.includeVideo) {
        return _pickVideo(options);
      } else {
        return _pickImage(options);
      }
    } catch (e) {
      if (e is MediaException) {
        rethrow;
      }
      throw MediaOperationException('Failed to pick media: ${e.toString()}');
    }
  }

  /// Crop the selected image - with safe guard against concurrent calls
  Future<MediaItem?> cropImage(
    MediaItem mediaItem,
    CropOptions cropOptions,
  ) async {
    // Prevent concurrent cropping
    if (_isCropping) {
      throw MediaOperationException('Another crop operation is in progress');
    }

    try {
      _isCropping = true;

      if (mediaItem.type != MediaType.image) {
        throw MediaTypeException('Cannot crop non-image media');
      }

      // Make a copy of the file before cropping to prevent issues
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(
        tempDir.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}${path.extension(mediaItem.path)}',
      );

      // Copy file to temporary location
      await File(mediaItem.path).copy(tempFilePath);

      // Wait briefly to ensure Android activity is ready
      await Future.delayed(const Duration(milliseconds: 200));

      final options = cropOptions.toCropperOptions();

      // Use try-catch specifically for the cropper to isolate issues
      CroppedFile? croppedFile;
      try {
        croppedFile = await _cropper.cropImage(
          sourcePath: tempFilePath,
          maxWidth: cropOptions.maxWidth,
          maxHeight: cropOptions.maxHeight,
          compressQuality: 90,
          uiSettings: options['uiSettings'] as List<PlatformUiSettings>,
        );
      } catch (cropError) {
        // Ignore specific errors that might be related to "Reply already submitted"
        if (cropError.toString().contains('Reply already submitted')) {
          // In this case, the crop might have succeeded but we got an error in reply
          // Try to check if a cropped file was created with standard naming pattern
          final potentialCroppedPath = tempFilePath.replaceFirst(
            RegExp(r'\.[^\.]+$'),
            '_cropped${path.extension(tempFilePath)}',
          );

          if (await File(potentialCroppedPath).exists()) {
            croppedFile = CroppedFile(potentialCroppedPath);
          }
        } else {
          // For other errors, rethrow
          rethrow;
        }
      }

      // Clean up the temp file
      try {
        await File(tempFilePath).delete();
      } catch (_) {}

      if (croppedFile == null) {
        return null;
      }

      return MediaItem.fromFile(File(croppedFile.path));
    } catch (e) {
      if (e is MediaException) {
        rethrow;
      }
      throw MediaOperationException('Failed to crop image: ${e.toString()}');
    } finally {
      _isCropping = false;
    }
  }

  /// Save media to temporary directory
  Future<MediaItem> saveMediaToTemp(
    MediaItem mediaItem, {
    String? filename,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          filename ??
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(mediaItem.path)}';
      final targetPath = path.join(tempDir.path, fileName);

      final File newFile = await mediaItem.file.copy(targetPath);

      return MediaItem(
        file: newFile,
        path: newFile.path,
        name: fileName,
        type: mediaItem.type,
        size: newFile.lengthSync(),
        thumbnail: mediaItem.thumbnail,
      );
    } catch (e) {
      throw MediaOperationException('Failed to save media: ${e.toString()}');
    }
  }

  /// Pick image(s) from gallery or camera
  Future<List<MediaItem>> _pickImage(MediaOptions options) async {
    try {
      if (options.allowMultiple && options.source == MediaSource.gallery) {
        // Pick multiple images
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          imageQuality: options.imageQuality,
          maxWidth: options.maxWidth?.toDouble(),
          maxHeight: options.maxHeight?.toDouble(),
        );

        if (pickedFiles.isEmpty) {
          return [];
        }

        List<MediaItem> mediaItems =
            pickedFiles
                .map((file) => MediaItem.fromFile(File(file.path)))
                .toList();

        // Apply cropping if requested - do one at a time
        if (options.cropOptions != null) {
          List<MediaItem> croppedItems = [];
          for (var item in mediaItems) {
            try {
              final cropped = await cropImage(item, options.cropOptions!);
              if (cropped != null) {
                croppedItems.add(cropped);
              } else {
                // Fallback to original if crop failed/canceled
                croppedItems.add(item);
              }
              // Add delay between crop operations
              if (mediaItems.indexOf(item) < mediaItems.length - 1) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } catch (e) {
              // On error, keep original item
              croppedItems.add(item);
            }
          }
          return croppedItems;
        }

        return mediaItems;
      } else {
        // Pick single image
        final XFile? pickedFile = await _picker.pickImage(
          source:
              options.source == MediaSource.camera
                  ? ImageSource.camera
                  : ImageSource.gallery,
          imageQuality: options.imageQuality,
          maxWidth: options.maxWidth?.toDouble(),
          maxHeight: options.maxHeight?.toDouble(),
          preferredCameraDevice: options.preferredCameraDevice,
        );

        if (pickedFile == null) {
          return [];
        }

        MediaItem mediaItem = MediaItem.fromFile(File(pickedFile.path));

        // Apply cropping if requested, but with safe handling
        if (options.cropOptions != null) {
          try {
            // Add delay before cropping
            await Future.delayed(const Duration(milliseconds: 300));
            final cropped = await cropImage(mediaItem, options.cropOptions!);
            return cropped != null ? [cropped] : [mediaItem];
          } catch (e) {
            return [mediaItem]; // Return original image on error
          }
        }

        return [mediaItem];
      }
    } catch (e) {
      throw MediaOperationException('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick video from gallery or camera
  Future<List<MediaItem>> _pickVideo(MediaOptions options) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source:
            options.source == MediaSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
        maxDuration: options.maxDuration,
      );

      if (pickedFile == null) {
        return [];
      }

      return [MediaItem.fromFile(File(pickedFile.path), type: MediaType.video)];
    } catch (e) {
      throw MediaOperationException('Failed to pick video: ${e.toString()}');
    }
  }
}
