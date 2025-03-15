import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logging/logging.dart';

import '../models/media_item.dart';
import '../models/media_options.dart';
import '../utils/media_exceptions.dart';

/// Loại thông báo
enum NotificationType { error, success, permission }

/// Handler cho các thông báo từ MediaController
abstract class MediaNotificationHandler {
  /// Xử lý thông báo
  void handleNotification(
    NotificationType type,
    String message, {
    dynamic data,
  });

  /// Yêu cầu quyền
  Future<bool> requestPermission(Permission permission, String message);
}

/// Handler mặc định sử dụng Logger
class DefaultMediaNotificationHandler implements MediaNotificationHandler {
  final Logger _logger;

  /// Constructor
  DefaultMediaNotificationHandler({Logger? logger})
    : _logger = logger ?? Logger('MediaController');

  @override
  void handleNotification(
    NotificationType type,
    String message, {
    dynamic data,
  }) {
    switch (type) {
      case NotificationType.error:
        _logger.warning('$message${data != null ? " | Data: $data" : ""}');
        break;
      case NotificationType.success:
        _logger.info('$message${data != null ? " | Data: $data" : ""}');
        break;
      default:
        _logger.fine('$message${data != null ? " | Data: $data" : ""}');
    }
  }

  @override
  Future<bool> requestPermission(Permission permission, String message) async {
    _logger.info('Permission request: ${permission.toString()} - $message');
    return true; // Luôn cho phép request
  }
}

/// Controller for handling media operations
class MediaController {
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final MediaNotificationHandler _notificationHandler;
  final Logger _logger = Logger('MediaController');

  bool _isCropping = false;

  /// Khởi tạo với notification handler tùy chọn
  MediaController({MediaNotificationHandler? notificationHandler})
    : _notificationHandler =
          notificationHandler ?? DefaultMediaNotificationHandler();

  /// Setup logger cho controller
  static void setupLogging({Level logLevel = Level.INFO}) {
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((record) {
      // Chỉ log vào debug console, không lưu log file hay hiển thị UI
      // Người dùng package cần tự cấu hình logger nếu muốn
      if (record.level >= Level.INFO) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.time}: ${record.message}');
      }
    });
  }

  /// Select media from gallery or camera
  Future<List<MediaItem>> pickMedia(MediaOptions options) async {
    try {
      _logger.fine('Bắt đầu chọn media với options: $options');

      // Kiểm tra quyền
      await _checkPermissions(options);

      // Pick media from selected source
      List<MediaItem> result;
      if (options.includeVideo) {
        result = await _pickVideo(options);
      } else {
        result = await _pickImage(options);
      }

      if (result.isNotEmpty) {
        _logger.info('Đã chọn ${result.length} media item');
        _notificationHandler.handleNotification(
          NotificationType.success,
          'Đã chọn ${result.length} media item',
          data: result.length == 1 ? result.first : null,
        );
      }

      return result;
    } catch (e) {
      if (e is MediaException) {
        _logger.warning('MediaException: ${e.message}');
        _notificationHandler.handleNotification(
          NotificationType.error,
          e.message,
          data: e,
        );
        rethrow;
      }
      final exception = MediaOperationException(
        'Không thể chọn media: ${e.toString()}',
      );
      _logger.severe('Lỗi không xác định: ${e.toString()}');
      _notificationHandler.handleNotification(
        NotificationType.error,
        exception.message,
        data: exception,
      );
      throw exception;
    }
  }

  /// Kiểm tra và yêu cầu quyền cần thiết
  Future<void> _checkPermissions(MediaOptions options) async {
    if (options.source == MediaSource.camera) {
      // Quyền camera
      await _requestAndVerifyPermission(
        Permission.camera,
        'Ứng dụng cần quyền truy cập camera để chụp ảnh',
      );

      // Quyền microphone cho video
      if (options.includeVideo) {
        await _requestAndVerifyPermission(
          Permission.microphone,
          'Ứng dụng cần quyền truy cập microphone để ghi âm video',
        );
      }
    } else {
      // Quyền gallery/storage
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;

        if (sdkVersion >= 33) {
          await _requestAndVerifyPermission(
            Permission.photos,
            'Ứng dụng cần quyền truy cập thư viện ảnh',
          );
        } else {
          await _requestAndVerifyPermission(
            Permission.storage,
            'Ứng dụng cần quyền truy cập bộ nhớ để mở thư viện ảnh',
          );
        }
      } else if (Platform.isIOS) {
        await _requestAndVerifyPermission(
          Permission.photos,
          'Ứng dụng cần quyền truy cập thư viện ảnh',
        );
      }
    }
  }

  /// Yêu cầu và kiểm tra quyền
  Future<void> _requestAndVerifyPermission(
    Permission permission,
    String message,
  ) async {
    _logger.fine('Yêu cầu quyền: ${permission.toString()}');

    // Yêu cầu xác nhận trước khi request quyền
    final shouldRequest = await _notificationHandler.requestPermission(
      permission,
      message,
    );
    if (!shouldRequest) {
      _logger.warning(
        'Người dùng từ chối xác nhận quyền: ${permission.toString()}',
      );
      throw MediaPermissionException(
        'Người dùng từ chối xác nhận quyền: ${permission.toString()}',
      );
    }

    // Yêu cầu quyền
    final status = await permission.request();
    if (!status.isGranted) {
      _logger.warning(
        'Quyền không được cấp: ${permission.toString()} - Status: ${status.toString()}',
      );
      throw MediaPermissionException(
        'Quyền không được cấp: ${permission.toString()}',
      );
    }

    _logger.fine('Đã được cấp quyền: ${permission.toString()}');
  }

  /// Crop selected image
  Future<MediaItem?> cropImage(
    MediaItem mediaItem,
    CropOptions cropOptions,
  ) async {
    if (_isCropping) {
      _logger.warning('Đang có thao tác crop khác đang xử lý');
      _notificationHandler.handleNotification(
        NotificationType.error,
        'Đang có thao tác crop khác đang xử lý',
      );
      throw MediaOperationException('Đang có thao tác crop khác đang xử lý');
    }

    try {
      _isCropping = true;
      _logger.fine('Bắt đầu crop ảnh: ${mediaItem.path}');

      if (mediaItem.type != MediaType.image) {
        _logger.warning('Không thể crop media không phải ảnh');
        throw MediaTypeException('Không thể crop media không phải ảnh');
      }

      // Copy file vào thư mục tạm
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(
        tempDir.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}${path.extension(mediaItem.path)}',
      );

      await File(mediaItem.path).copy(tempFilePath);
      await Future.delayed(const Duration(milliseconds: 200));

      final options = cropOptions.toCropperOptions();

      _logger.fine('Gọi image_cropper với sourcePath: $tempFilePath');
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
        _logger.warning('Lỗi khi crop: ${cropError.toString()}');
        // Xử lý lỗi đặc biệt "Reply already submitted"
        if (cropError.toString().contains('Reply already submitted')) {
          final potentialCroppedPath = tempFilePath.replaceFirst(
            RegExp(r'\.[^\.]+$'),
            '_cropped${path.extension(tempFilePath)}',
          );

          _logger.fine('Kiểm tra file thay thế: $potentialCroppedPath');
          if (await File(potentialCroppedPath).exists()) {
            _logger.info('Tìm thấy file crop thay thế');
            croppedFile = CroppedFile(potentialCroppedPath);
          }
        } else {
          rethrow;
        }
      }

      // Xóa file tạm
      try {
        await File(tempFilePath).delete();
        _logger.fine('Đã xóa file tạm: $tempFilePath');
      } catch (e) {
        _logger.fine('Không thể xóa file tạm: $e');
      }

      if (croppedFile == null) {
        _logger.info('Người dùng đã hủy thao tác crop');
        return null;
      }

      final result = MediaItem.fromFile(File(croppedFile.path));
      _logger.info('Đã crop ảnh thành công: ${result.path}');
      _notificationHandler.handleNotification(
        NotificationType.success,
        'Đã crop ảnh thành công',
        data: result,
      );

      return result;
    } catch (e) {
      if (e is MediaException) {
        _logger.warning('MediaException khi crop: ${e.message}');
        _notificationHandler.handleNotification(
          NotificationType.error,
          e.message,
          data: e,
        );
        rethrow;
      }

      _logger.severe('Lỗi không xác định khi crop: ${e.toString()}');
      final exception = MediaOperationException(
        'Không thể crop ảnh: ${e.toString()}',
      );
      _notificationHandler.handleNotification(
        NotificationType.error,
        exception.message,
        data: exception,
      );
      throw exception;
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
      _logger.fine('Bắt đầu lưu media: ${mediaItem.path}');
      final tempDir = await getTemporaryDirectory();
      final fileName =
          filename ??
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(mediaItem.path)}';
      final targetPath = path.join(tempDir.path, fileName);

      final File newFile = await mediaItem.file.copy(targetPath);
      _logger.fine('Đã copy file tới: $targetPath');

      final result = MediaItem(
        file: newFile,
        path: newFile.path,
        name: fileName,
        type: mediaItem.type,
        size: newFile.lengthSync(),
        thumbnail: mediaItem.thumbnail,
      );

      _logger.info('Đã lưu media vào thư mục tạm: $targetPath');
      _notificationHandler.handleNotification(
        NotificationType.success,
        'Đã lưu media vào thư mục tạm',
        data: result,
      );

      return result;
    } catch (e) {
      _logger.severe('Lỗi khi lưu media: ${e.toString()}');
      final exception = MediaOperationException(
        'Không thể lưu media: ${e.toString()}',
      );
      _notificationHandler.handleNotification(
        NotificationType.error,
        exception.message,
        data: exception,
      );
      throw exception;
    }
  }

  /// Pick image(s) from gallery or camera
  Future<List<MediaItem>> _pickImage(MediaOptions options) async {
    try {
      _logger.fine('Bắt đầu chọn ảnh với source: ${options.source}');
      if (options.allowMultiple && options.source == MediaSource.gallery) {
        // Chọn nhiều ảnh
        _logger.fine('Chọn nhiều ảnh từ gallery');
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          imageQuality: options.imageQuality,
          maxWidth: options.maxWidth?.toDouble(),
          maxHeight: options.maxHeight?.toDouble(),
        );

        if (pickedFiles.isEmpty) {
          _logger.info('Người dùng không chọn ảnh nào');
          return [];
        }

        List<MediaItem> mediaItems =
            pickedFiles
                .map((file) => MediaItem.fromFile(File(file.path)))
                .toList();
        _logger.fine('Đã chọn ${mediaItems.length} ảnh');

        // Áp dụng crop nếu có yêu cầu
        if (options.cropOptions != null) {
          _logger.fine('Bắt đầu crop ${mediaItems.length} ảnh');
          List<MediaItem> croppedItems = [];
          for (var item in mediaItems) {
            try {
              final cropped = await cropImage(item, options.cropOptions!);
              if (cropped != null) {
                croppedItems.add(cropped);
              } else {
                croppedItems.add(item);
              }

              if (mediaItems.indexOf(item) < mediaItems.length - 1) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } catch (e) {
              _logger.warning('Lỗi khi crop ảnh ${item.path}: $e');
              croppedItems.add(item);
            }
          }
          return croppedItems;
        }

        return mediaItems;
      } else {
        // Chọn một ảnh
        _logger.fine(
          'Chọn một ảnh từ ${options.source == MediaSource.camera ? 'camera' : 'gallery'}',
        );
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
          _logger.info('Người dùng không chọn ảnh');
          return [];
        }

        MediaItem mediaItem = MediaItem.fromFile(File(pickedFile.path));
        _logger.fine('Đã chọn ảnh: ${mediaItem.path}');

        // Áp dụng crop nếu có yêu cầu
        if (options.cropOptions != null) {
          _logger.fine('Bắt đầu crop ảnh');
          try {
            await Future.delayed(const Duration(milliseconds: 300));
            final cropped = await cropImage(mediaItem, options.cropOptions!);
            return cropped != null ? [cropped] : [mediaItem];
          } catch (e) {
            _logger.warning('Lỗi khi crop ảnh: $e');
            return [mediaItem];
          }
        }

        return [mediaItem];
      }
    } catch (e) {
      _logger.severe('Lỗi khi chọn ảnh: ${e.toString()}');
      throw MediaOperationException('Không thể chọn ảnh: ${e.toString()}');
    }
  }

  /// Pick video from gallery or camera
  Future<List<MediaItem>> _pickVideo(MediaOptions options) async {
    try {
      _logger.fine(
        'Bắt đầu chọn video từ ${options.source == MediaSource.camera ? 'camera' : 'gallery'}',
      );
      final XFile? pickedFile = await _picker.pickVideo(
        source:
            options.source == MediaSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
        maxDuration: options.maxDuration,
      );

      if (pickedFile == null) {
        _logger.info('Người dùng không chọn video');
        return [];
      }

      final result = [
        MediaItem.fromFile(File(pickedFile.path), type: MediaType.video),
      ];
      _logger.fine('Đã chọn video: ${result.first.path}');
      return result;
    } catch (e) {
      _logger.severe('Lỗi khi chọn video: ${e.toString()}');
      throw MediaOperationException('Không thể chọn video: ${e.toString()}');
    }
  }
}
