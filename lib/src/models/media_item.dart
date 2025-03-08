import 'dart:io';

//loại file
enum MediaType { image, video }

class MediaItem {
  final File file;
  final String path;
  final String name;
  final MediaType type;
  final int? size;
  final File? thumbnail;

  MediaItem({
    required this.file,
    required this.path,
    required this.name,
    required this.type,
    this.size,
    this.thumbnail,
  });

  factory MediaItem.fromFile(File file, {MediaType? type}) {
    final path = file.path;
    final name = path.split('/').last;
    final fileType =
        type ??
        (path.toLowerCase().endsWith('.mp4') ||
                path.toLowerCase().endsWith('.mov')
            ? MediaType.video
            : MediaType.image);

    return MediaItem(
      file: file,
      path: path,
      name: name,
      type: fileType,
      size: file.lengthSync(),
    );
  }

  /// Clone the MediaItem with optional new values
  MediaItem copyWith({
    File? file,
    String? path,
    String? name,
    MediaType? type,
    int? size,
    File? thumbnail,
  }) {
    return MediaItem(
      file: file ?? this.file,
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}
