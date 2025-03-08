import 'package:flutter/material.dart';
import '../models/media_item.dart';

/// Widget to preview a media item (image or video)
class MediaPreview extends StatelessWidget {
  /// The media item to preview
  final MediaItem mediaItem;

  /// Width of the preview
  final double? width;

  /// Height of the preview
  final double? height;

  /// Fit mode for the media
  final BoxFit fit;

  /// Border radius for the preview
  final BorderRadius? borderRadius;

  /// Whether to show a delete button
  final bool showDeleteButton;

  /// Callback when delete button is pressed
  final VoidCallback? onDelete;

  /// Widget to display when media is loading
  final Widget? loadingWidget;

  /// Widget to display on error
  final Widget? errorWidget;

  const MediaPreview({
    super.key,
    required this.mediaItem,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showDeleteButton = false,
    this.onDelete,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: _buildPreview(),
        ),
        if (showDeleteButton) _buildDeleteButton(),
      ],
    );
  }

  Widget _buildPreview() {
    if (mediaItem.type == MediaType.image) {
      return _buildImagePreview();
    } else {
      return _buildVideoPreview();
    }
  }

  Widget _buildImagePreview() {
    return Image.file(
      mediaItem.file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultErrorWidget();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return loadingWidget ?? _defaultLoadingWidget();
      },
    );
  }

  Widget _buildVideoPreview() {
    // For video, we just show thumbnail or placeholder
    if (mediaItem.thumbnail != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            mediaItem.thumbnail!,
            width: width,
            height: height,
            fit: fit,
          ),
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
        ],
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            color: Colors.black26,
            child: const Icon(Icons.video_file, color: Colors.white, size: 48),
          ),
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
        ],
      );
    }
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _defaultLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
    );
  }
}
