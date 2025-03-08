import 'package:flutter/material.dart';
import 'package:media_module/src/controllers/media_controller.dart';
import '../models/media_item.dart';
import '../models/media_options.dart';
import '../utils/media_exceptions.dart';

/// A button widget that opens media picker with specified options
class MediaPickerButton extends StatelessWidget {
  /// Text to display on the button
  final String text;

  /// Icon to display on the button
  final IconData? icon;

  /// Options for media picker
  final MediaOptions options;

  /// Callback when media is selected
  final Function(List<MediaItem>) onMediaSelected;

  /// Callback for errors
  final Function(MediaException)? onError;

  /// Loading state of the button
  final bool isLoading;

  /// Button style
  final ButtonStyle? style;

  /// Controller for media operations
  final MediaController controller;

  /// Show a bottom sheet with options
  final bool showBottomSheet;

  /// Text for camera option in bottom sheet
  final String cameraOptionText;

  /// Text for gallery option in bottom sheet
  final String galleryOptionText;

  const MediaPickerButton({
    super.key,
    required this.text,
    this.icon,
    required this.options,
    required this.onMediaSelected,
    this.onError,
    this.isLoading = false,
    this.style,
    required this.controller,
    this.showBottomSheet = false,
    this.cameraOptionText = 'Take Photo',
    this.galleryOptionText = 'Choose from Gallery',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading ? null : () => _handlePress(context),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(width: 8), Text(text)],
      );
    }

    return Text(text);
  }

  Future<void> _handlePress(BuildContext context) async {
    if (showBottomSheet) {
      _showSourceBottomSheet(context);
    } else {
      _pickMedia(options);
    }
  }

  void _showSourceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(cameraOptionText),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(
                    MediaOptions.camera(
                      maxWidth: options.maxWidth,
                      maxHeight: options.maxHeight,
                      imageQuality: options.imageQuality,
                      cropOptions: options.cropOptions,
                      includeVideo: options.includeVideo,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(galleryOptionText),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(
                    MediaOptions.gallery(
                      maxWidth: options.maxWidth,
                      maxHeight: options.maxHeight,
                      imageQuality: options.imageQuality,
                      allowMultiple: options.allowMultiple,
                      cropOptions: options.cropOptions,
                      includeVideo: options.includeVideo,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(MediaOptions mediaOptions) async {
    try {
      final List<MediaItem> selectedMedia = await controller.pickMedia(
        mediaOptions,
      );
      if (selectedMedia.isNotEmpty) {
        onMediaSelected(selectedMedia);
      }
    } on MediaException catch (e) {
      if (onError != null) {
        onError!(e);
      }
    } catch (e) {
      if (onError != null) {
        onError!(MediaOperationException(e.toString()));
      }
    }
  }
}
