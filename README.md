# My Media Module

![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Một package Flutter đơn giản để xử lý hình ảnh và video với API trực quan, dễ sử dụng. Package này giúp đơn giản hóa các tác vụ phức tạp như chọn ảnh từ thư viện, chụp ảnh từ camera, cắt ảnh và quản lý các file media.

## Tính năng chính

- ✨ Chọn ảnh/video từ thư viện hoặc camera
- 🖼️ Hỗ trợ chọn nhiều ảnh cùng lúc
- ✂️ Cắt và chỉnh sửa ảnh với nhiều tùy chọn
- 📱 Xem trước media với widget có thể tùy chỉnh
- 🔒 Tự động xử lý quyền truy cập (camera, thư viện ảnh)
- 🧩 API đơn giản, dễ tích hợp

## Cài đặt

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  my_media_module:
    git:
      url: https://github.com/Cat1m/media_module.git
      ref: main  # hoặc tag cụ thể
```

## Sử dụng cơ bản

### Khởi tạo controller

```dart
final _mediaController = MediaController();
```

### Chọn ảnh từ thư viện

```dart
try {
  final result = await _mediaController.pickMedia(
    MediaOptions.gallery(
      allowMultiple: true,
      imageQuality: 80,
    ),
  );
  
  if (result != null && result.isNotEmpty) {
    // Xử lý ảnh đã chọn
    setState(() {
      _selectedMedia.addAll(result);
    });
  }
} catch (e) {
  // Xử lý lỗi
  print('Lỗi chọn ảnh: $e');
}
```

### Chụp ảnh từ camera

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
  print('Lỗi chụp ảnh: $e');
}
```

### Sử dụng MediaPickerButton

```dart
MediaPickerButton(
  text: 'Chọn Media',
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
      SnackBar(content: Text('Lỗi: ${error.message}')),
    );
  },
)
```

### Cắt ảnh đã chọn

```dart
final croppedImage = await _mediaController.cropImage(
  _selectedMedia[index],
  const CropOptions(
    aspectRatio: CropAspectRatio.square,
    uiOptions: CropUIOptions(toolbarTitle: 'Chỉnh sửa ảnh'),
  ),
);

if (croppedImage != null) {
  setState(() {
    _selectedMedia[index] = croppedImage;
  });
}
```

### Hiển thị ảnh với MediaPreview

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

## Cấu hình quyền truy cập và thư viện

### Android

Thêm vào file `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### Cấu hình Image Cropper cho Android

1. Thêm UCropActivity vào AndroidManifest.xml:

```xml
<activity
  android:name="com.yalantis.ucrop.UCropActivity"
  android:screenOrientation="portrait"
  android:theme="@style/Ucrop.CropTheme"/>
```

2. Thêm style cho Ucrop vào file `android/app/src/main/res/values/styles.xml`:

```xml
<resources>
  <!-- Các style khác của bạn -->
  <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar"/>
</resources>
```

3. Tạo file mới `android/app/src/main/res/values-v35/styles.xml` để hỗ trợ Android 15 (Edge-to-Edge mode):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar">
      <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
  </style>
</resources>
```

### iOS

Thêm vào file `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để chụp ảnh</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh để chọn hình ảnh</string>
<key>NSMicrophoneUsageDescription</key>
<string>Ứng dụng cần quyền truy cập microphone để quay video</string>
```

#### Cấu hình Image Cropper cho iOS

Image Cropper trên iOS không yêu cầu cấu hình bổ sung. Tính năng này sử dụng thư viện TOCropViewController và sẽ hoạt động ngay sau khi package được cài đặt.

### Web

#### Cấu hình Image Cropper cho Web

Để hỗ trợ cắt ảnh trên web, thêm các thẻ script và css vào file `web/index.html` trong thẻ `<head>`:

```html
<head>
  <!-- Các thẻ khác của bạn -->

  <!-- cropperjs -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>

  <!-- Các thẻ khác của bạn -->
</head>
```

> **Lưu ý**: Để sử dụng cropper trên web, bạn cần đảm bảo luôn cung cấp `WebUiSettings` trong `uiSettings` của options.

## Tùy chọn nâng cao

### Tùy chỉnh CropOptions

```dart
CropOptions(
  aspectRatio: CropAspectRatio.ratio16x9,
  maxWidth: 1920,
  maxHeight: 1080,
  uiOptions: CropUIOptions(
    toolbarTitle: 'Tùy chỉnh ảnh',
    toolbarColor: Colors.black,
    toolbarTextColor: Colors.white,
    activeControlsColor: Colors.blue,
    doneButtonText: 'Xong',
    cancelButtonText: 'Hủy',
  ),
)
```

### Ví dụ chi tiết về cắt ảnh

Dưới đây là ví dụ đầy đủ về cách sử dụng `cropImage` với các cấu hình UI khác nhau cho từng nền tảng:

```dart
final croppedImage = await _mediaController.cropImage(
  selectedImage,
  CropOptions(
    maxWidth: 1080,
    maxHeight: 1080,
    aspectRatio: CropAspectRatio.square,
    uiOptions: CropUIOptions(
      toolbarTitle: 'Chỉnh sửa ảnh',
      toolbarColor: Colors.deepOrange,
      toolbarTextColor: Colors.white,
      activeControlsColor: Colors.blue,
      doneButtonText: 'Hoàn tất',
      cancelButtonText: 'Hủy bỏ',
    ),
  ),
);

if (croppedImage != null) {
  setState(() {
    // Cập nhật ảnh đã cắt
    _selectedMedia[index] = croppedImage;
  });
}
```

### Tùy chỉnh tỷ lệ cắt (Aspect Ratio)

Module hỗ trợ các tỷ lệ cắt ảnh sau:

```dart
enum CropAspectRatio {
  original,  // Giữ nguyên tỷ lệ gốc
  square,    // Vuông (1:1)
  ratio3x2,  // Tỷ lệ 3:2
  ratio4x3,  // Tỷ lệ 4:3 
  ratio5x3,  // Tỷ lệ 5:3
  ratio5x4,  // Tỷ lệ 5:4
  ratio7x5,  // Tỷ lệ 7:5
  ratio16x9, // Tỷ lệ 16:9
}
```

### MediaOptions cho gallery

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

### MediaOptions cho camera

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

## Xử lý lỗi

```dart
try {
  // Thực hiện các thao tác media
} on MediaPermissionException catch (e) {
  // Xử lý lỗi quyền truy cập
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cần cấp quyền'),
      content: Text(e.message),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Mở cài đặt'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
} on MediaOperationException catch (e) {
  // Xử lý lỗi thao tác
  showSnackBar(e.message);
} on MediaTypeException catch (e) {
  // Xử lý lỗi định dạng
  showSnackBar(e.message);
} catch (e) {
  // Xử lý lỗi khác
  showSnackBar('Đã xảy ra lỗi: $e');
}
```

## Ứng dụng mẫu

Package này cung cấp một ứng dụng mẫu đầy đủ trong thư mục `example`. Bạn có thể xem và chạy để hiểu rõ hơn cách sử dụng package.

```bash
cd example
flutter run
```

## API Reference

### Classes

- `MediaController`: Controller chính để thực hiện các thao tác media
- `MediaItem`: Đại diện cho một file media (ảnh hoặc video)
- `MediaOptions`: Cấu hình cho việc chọn media
- `CropOptions`: Cấu hình cho việc cắt ảnh
- `MediaPickerButton`: Widget button để chọn media
- `MediaPreview`: Widget hiển thị xem trước media

### Enums

- `MediaType`: Loại media (image, video)
- `MediaSource`: Nguồn media (gallery, camera)
- `CropAspectRatio`: Tỷ lệ khung hình cho cắt ảnh

## Yêu cầu

- Flutter: >=1.17.0
- Dart: >=3.7.0
- Android: minSdkVersion 21 (Android 5.0)
- iOS: iOS 11.0 trở lên

## Các package phụ thuộc

- `image_picker`: ^1.1.2
- `image_cropper`: ^9.0.0
- `path_provider`: ^2.1.5
- `permission_handler`: ^11.4.0

## Đóng góp

Mọi đóng góp đều được hoan nghênh! Nếu bạn phát hiện lỗi hoặc có ý tưởng cải thiện package, vui lòng tạo issue hoặc gửi pull request.

## License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.