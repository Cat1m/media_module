# Media Module

![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

*[Tiếng Việt](README_vi.md)*

A simple Flutter package for handling images and videos with an intuitive, easy-to-use API. This package simplifies complex tasks such as selecting images from the gallery, taking photos with the camera, cropping images, and managing media files.

## Key Features

- ✨ Select images/videos from gallery or camera
- 🖼️ Support for selecting multiple images at once
- ✂️ Crop and edit images with various options
- 📱 Preview media with customizable widgets
- 🔒 Automatic permission handling (camera, photo library)
- 🧩 Simple, easy-to-integrate API

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  media_module:
    git:
      url: https://github.com/Cat1m/media_module.git
      ref: main  # or specific tag
```

## Basic Usage

### Initialize the controller

```dart
final _mediaController = MediaController();
```

### Select images from gallery

```dart
try {
  final result = await _mediaController.pickMedia(
    MediaOptions.gallery(
      allowMultiple: true,
      imageQuality: 80,
    ),
  );
  
  if (result != null && result.isNotEmpty) {
    // Process selected images
    setState(() {
      _selectedMedia.addAll(result);
    });
  }
} catch (e) {
  // Handle errors
  print('Error selecting images: $e');
}
```

### Take a photo with the camera

```dart
try {
  final result = await _mediaController.pickMedia(
    MediaOptions.camera(
      imageQuality: 90,
      cropOptions: const CropOptions(
        aspectRatio: CropAspectRatio.square,
      ),
    ),
  );
  
  if (result != null && result.isNotEmpty) {
    setState(() {
      _selectedMedia.addAll(result);
    });
  }
} catch (e) {
  print('Error taking photo: $e');
}
```

### Using MediaPickerButton

```dart
MediaPickerButton(
  text: 'Select Media',
  icon: Icons.add_photo_alternate,
  options: const MediaOptions(
    allowMultiple: true,
    imageQuality: 80,
  ),
  controller: _mediaController,
  showBottomSheet: true,
  onMediaSelected: (media) {
    setState(() {
      _selectedMedia.addAll(media);
    });
  },
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.message}')),
    );
  },
)
```

### Crop a selected image

```dart
final croppedImage = await _mediaController.cropImage(
  _selectedMedia[index],
  const CropOptions(
    aspectRatio: CropAspectRatio.square,
    uiOptions: CropUIOptions(toolbarTitle: 'Edit Image'),
  ),
);

if (croppedImage != null) {
  setState(() {
    _selectedMedia[index] = croppedImage;
  });
}
```

### Display an image with MediaPreview

```dart
MediaPreview(
  mediaItem: _selectedMedia[index],
  borderRadius: BorderRadius.circular(8),
  showDeleteButton: true,
  onDelete: () {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  },
)
```

## Permission and Library Configuration

### Android

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### Image Cropper Configuration for Android

1. Add UCropActivity to your AndroidManifest.xml:

```xml
<activity
  android:name="com.yalantis.ucrop.UCropActivity"
  android:screenOrientation="portrait"
  android:theme="@style/Ucrop.CropTheme"/>
```

2. Add Ucrop style to your `android/app/src/main/res/values/styles.xml`:

```xml
<resources>
  <!-- Your other styles -->
  <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar"/>
</resources>
```

3. Create a new file `android/app/src/main/res/values-v35/styles.xml` to support Android 15 (Edge-to-Edge mode):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar">
      <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
  </style>
</resources>
```

### iOS

Add to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
```

#### Image Cropper Configuration for iOS

Image Cropper on iOS does not require additional configuration. This feature uses the TOCropViewController library and will work as soon as the package is installed.

### Web

#### Image Cropper Configuration for Web

To support image cropping on the web, add the following script and CSS tags to your `web/index.html` file in the `<head>` tag:

```html
<head>
  <!-- Your other tags -->

  <!-- cropperjs -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>

  <!-- Your other tags -->
</head>
```

> **Note**: To use the cropper on the web, you need to make sure you always provide `WebUiSettings` in the `uiSettings` of your options.

## Advanced Options

### CropOptions Customization

```dart
CropOptions(
  aspectRatio: CropAspectRatio.ratio16x9,
  maxWidth: 1920,
  maxHeight: 1080,
  uiOptions: CropUIOptions(
    toolbarTitle: 'Customize Image',
    toolbarColor: Colors.black,
    toolbarTextColor: Colors.white,
    activeControlsColor: Colors.blue,
    doneButtonText: 'Done',
    cancelButtonText: 'Cancel',
  ),
)
```

### Detailed Example of Image Cropping

Here's a comprehensive example of using `cropImage` with different UI configurations for each platform:

```dart
final croppedImage = await _mediaController.cropImage(
  selectedImage,
  CropOptions(
    maxWidth: 1080,
    maxHeight: 1080,
    aspectRatio: CropAspectRatio.square,
    uiOptions: CropUIOptions(
      toolbarTitle: 'Edit Image',
      toolbarColor: Colors.deepOrange,
      toolbarTextColor: Colors.white,
      activeControlsColor: Colors.blue,
      doneButtonText: 'Complete',
      cancelButtonText: 'Cancel',
    ),
  ),
);

if (croppedImage != null) {
  setState(() {
    // Update the cropped image
    _selectedMedia[index] = croppedImage;
  });
}
```

### Crop Aspect Ratio Customization

The module supports the following crop aspect ratios:

```dart
enum CropAspectRatio {
  original,  // Keep original aspect ratio
  square,    // Square (1:1)
  ratio3x2,  // 3:2 ratio
  ratio4x3,  // 4:3 ratio
  ratio5x3,  // 5:3 ratio
  ratio5x4,  // 5:4 ratio
  ratio7x5,  // 7:5 ratio
  ratio16x9, // 16:9 ratio
}
```

### MediaOptions for Gallery

```dart
MediaOptions.gallery(
  maxWidth: 1200,
  maxHeight: 1200,
  imageQuality: 85,
  allowMultiple: true,
  includeVideo: true,
  cropOptions: cropOptions,
)
```

### MediaOptions for Camera

```dart
MediaOptions.camera(
  maxWidth: 1200,
  maxHeight: 1200,
  imageQuality: 90,
  preferredCameraDevice: CameraDevice.front,
  includeVideo: true,
  maxDuration: const Duration(seconds: 30),
  cropOptions: cropOptions,
)
```

## Error Handling

```dart
try {
  // Perform media operations
} on MediaPermissionException catch (e) {
  // Handle permission errors
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permission Required'),
      content: Text(e.message),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Open Settings'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
} on MediaOperationException catch (e) {
  // Handle operation errors
  showSnackBar(e.message);
} on MediaTypeException catch (e) {
  // Handle format errors
  showSnackBar(e.message);
} catch (e) {
  // Handle other errors
  showSnackBar('An error occurred: $e');
}
```

## Example App

This package provides a complete example app in the `example` directory. You can view and run it to better understand how to use the package.

```bash
cd example
flutter run
```

## API Reference

### Classes

- `MediaController`: Main controller for performing media operations
- `MediaItem`: Represents a media file (image or video)
- `MediaOptions`: Configuration for media selection
- `CropOptions`: Configuration for image cropping
- `MediaPickerButton`: Button widget for selecting media
- `MediaPreview`: Widget for displaying media previews

### Enums

- `MediaType`: Media type (image, video)
- `MediaSource`: Media source (gallery, camera)
- `CropAspectRatio`: Aspect ratio for cropping

## Requirements

- Flutter: >=1.17.0
- Dart: >=3.7.0
- Android: minSdkVersion 21 (Android 5.0)
- iOS: iOS 11.0 or later

## Dependencies

- `image_picker`: ^1.1.2
- `image_cropper`: ^9.0.0
- `path_provider`: ^2.1.5
- `permission_handler`: ^11.4.0

## Contributing

Contributions are welcome! If you find a bug or have ideas to improve the package, please create an issue or submit a pull request.

## License

MIT License - see the [LICENSE](LICENSE) file for details.