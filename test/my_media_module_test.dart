import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_media_module/my_media_module.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock for path provider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return '/test/temp';
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return '/test/cache';
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/test/documents';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '/test/support';
  }

  @override
  Future<String?> getDownloadsPath() async {
    return '/test/downloads';
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['/test/external/cache'];
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return '/test/external/storage';
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return ['/test/external/storage/path'];
  }

  @override
  Future<String?> getLibraryPath() async {
    return '/test/library';
  }
}

void main() {
  setUpAll(() {
    // Set up mocks
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('MediaItem Tests', () {
    test('Create MediaItem from file', () {
      final testFile = File('test_file.jpg');
      final mediaItem = MediaItem.fromFile(testFile);

      expect(mediaItem.file, equals(testFile));
      expect(mediaItem.path, equals('test_file.jpg'));
      expect(mediaItem.type, equals(MediaType.image));
    });

    test('MediaItem copyWith', () {
      final testFile = File('test_file.jpg');
      final mediaItem = MediaItem.fromFile(testFile);
      final newFile = File('new_file.jpg');

      final copiedItem = mediaItem.copyWith(
        file: newFile,
        name: 'new_name.jpg',
      );

      expect(copiedItem.file, equals(newFile));
      expect(copiedItem.name, equals('new_name.jpg'));
      expect(copiedItem.type, equals(MediaType.image)); // Should be unchanged
    });
  });

  group('MediaOptions Tests', () {
    test('Default MediaOptions', () {
      const options = MediaOptions();

      expect(options.source, equals(MediaSource.gallery));
      expect(options.imageQuality, equals(80));
      expect(options.allowMultiple, equals(false));
    });

    test('MediaOptions.camera factory', () {
      final options = MediaOptions.camera(imageQuality: 90);

      expect(options.source, equals(MediaSource.camera));
      expect(options.imageQuality, equals(90));
      expect(options.preferredCameraDevice, equals(CameraDevice.rear));
    });

    test('MediaOptions.gallery factory', () {
      final options = MediaOptions.gallery(allowMultiple: true);

      expect(options.source, equals(MediaSource.gallery));
      expect(options.allowMultiple, equals(true));
    });
  });

  group('Widget Tests', () {
    testWidgets('MediaPickerButton renders correctly', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerButton(
              text: 'Select Media',
              options: const MediaOptions(),
              controller: MediaController(),
              onMediaSelected: (media) {},
            ),
          ),
        ),
      );

      // Verify that the button text appears
      expect(find.text('Select Media'), findsOneWidget);
    });

    testWidgets('MediaPreview renders placeholder for missing image', (
      WidgetTester tester,
    ) async {
      // Create a mock media item with a non-existent file
      final mediaItem = MediaItem(
        file: File('non_existent.jpg'),
        path: 'non_existent.jpg',
        name: 'non_existent.jpg',
        type: MediaType.image,
      );

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPreview(
              mediaItem: mediaItem,
              errorWidget: const Text('Error loading image'),
            ),
          ),
        ),
      );

      // Wait for the error to be triggered
      await tester.pump();

      // Verify that error widget is shown
      expect(find.text('Error loading image'), findsOneWidget);
    });
  });
}
