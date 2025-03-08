/// Base class for all media module exceptions
abstract class MediaException implements Exception {
  final String message;

  MediaException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when media operations fail
class MediaOperationException extends MediaException {
  MediaOperationException(super.message);
}

/// Exception thrown when permissions are denied
class MediaPermissionException extends MediaException {
  MediaPermissionException(super.message);
}

/// Exception thrown when there are issues with media type
class MediaTypeException extends MediaException {
  MediaTypeException(super.message);
}

/// Exception thrown when there are issues with file operations
class MediaFileException extends MediaException {
  MediaFileException(super.message);
}
