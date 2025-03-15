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
          // Sửa các vấn đề với thuộc tính kiểu double
          cropGridStrokeWidth: uiOptions!.cropGridStrokeWidth,
          cropFrameStrokeWidth: uiOptions!.cropFrameStrokeWidth,
          showCropGrid: uiOptions!.showCropGrid ?? true,
          lockAspectRatio: uiOptions!.lockAspectRatio ?? false,
          hideBottomControls: uiOptions!.hideBottomControls ?? false,
          statusBarColor: uiOptions!.statusBarColor,
          dimmedLayerColor: uiOptions!.dimmedLayerColor,
          backgroundColor: uiOptions!.backgroundColor,
        ),
      );

      // Add iOS settings
      uiSettingsList.add(
        IOSUiSettings(
          title: uiOptions!.toolbarTitle,
          doneButtonTitle: uiOptions!.doneButtonText,
          cancelButtonTitle: uiOptions!.cancelButtonText,
          // Các thuộc tính bổ sung cho iOS
          hidesNavigationBar: uiOptions!.hidesNavigationBar,
          aspectRatioPickerButtonHidden:
              uiOptions!.hideAspectRatioButton ?? false,
          resetButtonHidden: uiOptions!.hideResetButton ?? false,
          rotateButtonsHidden: uiOptions!.hideRotateButton ?? false,
          aspectRatioLockEnabled: uiOptions!.lockAspectRatio ?? false,
          resetAspectRatioEnabled: uiOptions!.resetAspectRatioEnabled ?? true,
          rotateClockwiseButtonHidden:
              uiOptions!.hideRotateClockwiseButton ?? false,
          minimumAspectRatio: uiOptions!.minimumAspectRatio,
          rectX: uiOptions!.initialCropRectX,
          rectY: uiOptions!.initialCropRectY,
          rectWidth: uiOptions!.initialCropRectWidth,
          rectHeight: uiOptions!.initialCropRectHeight,
        ),
      );
    } else {
      // Cung cấp thiết lập mặc định nếu không có uiOptions
      uiSettingsList.add(
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          initAspectRatio: _getDefaultAspectRatio(),
        ),
      );

      uiSettingsList.add(IOSUiSettings(title: 'Crop Image'));
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

  /// Show crop grid
  final bool? showCropGrid;

  /// Color for crop frame
  final Color? cropFrameColor;

  /// Color for crop grid
  final Color? cropGridColor;

  /// Stroke width for crop grid
  final int? cropGridStrokeWidth;

  /// Stroke width for crop frame
  final int? cropFrameStrokeWidth;

  /// Lock aspect ratio
  final bool? lockAspectRatio;

  /// Hide bottom controls
  final bool? hideBottomControls;

  /// Status bar color (Android)
  final Color? statusBarColor;

  /// Dimmed layer color (Android)
  final Color? dimmedLayerColor;

  /// Background color (Android)
  final Color? backgroundColor;

  /// Hide navigation bar (iOS)
  final bool? hidesNavigationBar;

  /// Hide reset button (iOS)
  final bool? hideResetButton;

  /// Hide rotate button (iOS)
  final bool? hideRotateButton;

  /// Hide aspect ratio button (iOS)
  final bool? hideAspectRatioButton;

  /// Hide rotate clockwise button (iOS)
  final bool? hideRotateClockwiseButton;

  /// Enable reset aspect ratio (iOS)
  final bool? resetAspectRatioEnabled;

  /// Minimum aspect ratio (iOS)
  final double? minimumAspectRatio;

  /// Initial crop rectangle X (iOS)
  final double? initialCropRectX;

  /// Initial crop rectangle Y (iOS)
  final double? initialCropRectY;

  /// Initial crop rectangle width (iOS)
  final double? initialCropRectWidth;

  /// Initial crop rectangle height (iOS)
  final double? initialCropRectHeight;

  const CropUIOptions({
    this.toolbarTitle = 'Crop Image',
    this.toolbarColor,
    this.toolbarTextColor,
    this.activeControlsColor,
    this.doneButtonText = 'Done',
    this.cancelButtonText = 'Cancel',
    this.showCropGrid,
    this.cropFrameColor,
    this.cropGridColor,
    this.cropGridStrokeWidth,
    this.cropFrameStrokeWidth,
    this.lockAspectRatio,
    this.hideBottomControls,
    this.statusBarColor,
    this.dimmedLayerColor,
    this.backgroundColor,
    this.hidesNavigationBar,
    this.hideResetButton,
    this.hideRotateButton,
    this.hideAspectRatioButton,
    this.hideRotateClockwiseButton,
    this.resetAspectRatioEnabled,
    this.minimumAspectRatio,
    this.initialCropRectX,
    this.initialCropRectY,
    this.initialCropRectWidth,
    this.initialCropRectHeight,
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
