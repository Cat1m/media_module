import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Options for configuring the media picker
class MediaOptions {
  /// Source for picking media (camera or gallery)
  final MediaSource source;

  /// Maximum width for image resizing
  final int? maxWidth;

  /// Maximum height for image resizing
  final int? maxHeight;

  /// Image quality (0 to 100)
  final int imageQuality;

  /// Whether to allow multiple selections
  final bool allowMultiple;

  /// Preferred camera device
  final CameraDevice preferredCameraDevice;

  /// Whether to include videos in gallery
  final bool includeVideo;

  /// Maximum duration for video recording
  final Duration? maxDuration;

  /// Options for cropping
  final CropOptions? cropOptions;

  const MediaOptions({
    this.source = MediaSource.gallery,
    this.maxWidth,
    this.maxHeight,
    this.imageQuality = 80,
    this.allowMultiple = false,
    this.preferredCameraDevice = CameraDevice.rear,
    this.includeVideo = false,
    this.maxDuration,
    this.cropOptions,
  });

  /// Create options for camera source
  factory MediaOptions.camera({
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 80,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool includeVideo = false,
    Duration? maxDuration,
    CropOptions? cropOptions,
  }) {
    return MediaOptions(
      source: MediaSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
      includeVideo: includeVideo,
      maxDuration: maxDuration,
      cropOptions: cropOptions,
    );
  }

  /// Create options for gallery source
  factory MediaOptions.gallery({
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 80,
    bool allowMultiple = false,
    bool includeVideo = false,
    CropOptions? cropOptions,
  }) {
    return MediaOptions(
      source: MediaSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      allowMultiple: allowMultiple,
      includeVideo: includeVideo,
      cropOptions: cropOptions,
    );
  }

  /// Get options for image picker
  Map<String, dynamic> getImagePickerConfig() {
    return {
      'maxWidth': maxWidth?.toDouble(),
      'maxHeight': maxHeight?.toDouble(),
      'imageQuality': imageQuality,
      'preferredCameraDevice': preferredCameraDevice,
    };
  }
}

/// Options for cropping images
class CropOptions {
  /// Aspect ratio for cropping
  final CropAspectRatio? aspectRatio;

  /// Maximum width after cropping
  final int? maxWidth;

  /// Maximum height after cropping
  final int? maxHeight;

  /// UI customization for cropper
  final CropUIOptions? uiOptions;

  const CropOptions({
    this.aspectRatio,
    this.maxWidth,
    this.maxHeight,
    this.uiOptions,
  });

  /// Convert to ImageCropper options for cropping
  Map<String, dynamic> toCropperOptions() {
    List<PlatformUiSettings> uiSettingsList = [];

    if (uiOptions != null) {
      // Add Android settings
      uiSettingsList.add(
        AndroidUiSettings(
          toolbarTitle: uiOptions!.toolbarTitle,
          toolbarColor: uiOptions!.toolbarColor ?? Colors.blue,
          toolbarWidgetColor: uiOptions!.toolbarTextColor ?? Colors.white,
          activeControlsWidgetColor:
              uiOptions!.activeControlsColor ?? Colors.blue,
          initAspectRatio: _getDefaultAspectRatio(),
        ),
      );

      // Add iOS settings
      uiSettingsList.add(
        IOSUiSettings(
          title: uiOptions!.toolbarTitle,
          doneButtonTitle: uiOptions!.doneButtonText,
          cancelButtonTitle: uiOptions!.cancelButtonText,
        ),
      );
    }

    return {'uiSettings': uiSettingsList};
  }

  /// Get default aspect ratio preset based on our enum
  CropAspectRatioPreset _getDefaultAspectRatio() {
    if (aspectRatio == null) return CropAspectRatioPreset.original;

    switch (aspectRatio) {
      case CropAspectRatio.original:
        return CropAspectRatioPreset.original;
      case CropAspectRatio.square:
        return CropAspectRatioPreset.square;
      case CropAspectRatio.ratio3x2:
        return CropAspectRatioPreset.ratio3x2;
      case CropAspectRatio.ratio4x3:
        return CropAspectRatioPreset.ratio4x3;
      case CropAspectRatio.ratio5x3:
        return CropAspectRatioPreset.ratio5x3;
      case CropAspectRatio.ratio5x4:
        return CropAspectRatioPreset.ratio5x4;
      case CropAspectRatio.ratio7x5:
        return CropAspectRatioPreset.ratio7x5;
      case CropAspectRatio.ratio16x9:
        return CropAspectRatioPreset.ratio16x9;
      case null:
        return CropAspectRatioPreset.original;
    }
  }
}

/// UI options for the image cropper
class CropUIOptions {
  /// Title for the cropper toolbar
  final String toolbarTitle;

  /// Background color for the toolbar
  final Color? toolbarColor;

  /// Text color for the toolbar
  final Color? toolbarTextColor;

  /// Color for active controls
  final Color? activeControlsColor;

  /// Text for the done button
  final String doneButtonText;

  /// Text for the cancel button
  final String cancelButtonText;

  const CropUIOptions({
    this.toolbarTitle = 'Crop Image',
    this.toolbarColor,
    this.toolbarTextColor,
    this.activeControlsColor,
    this.doneButtonText = 'Done',
    this.cancelButtonText = 'Cancel',
  });
}

/// Enum for crop aspect ratios
enum CropAspectRatio {
  original,
  square,
  ratio3x2,
  ratio4x3,
  ratio5x3,
  ratio5x4,
  ratio7x5,
  ratio16x9,
}

/// Enum for media sources
enum MediaSource { gallery, camera }
