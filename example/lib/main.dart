import 'package:flutter/material.dart';
import 'package:media_module/media_module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Module Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MediaModuleDemo(),
    );
  }
}

class MediaModuleDemo extends StatefulWidget {
  const MediaModuleDemo({super.key});

  @override
  State<MediaModuleDemo> createState() => _MediaModuleDemoState();
}

class _MediaModuleDemoState extends State<MediaModuleDemo>
    with WidgetsBindingObserver {
  // Create a controller
  final _mediaController = MediaController();

  // List of selected media items
  final List<MediaItem> _selectedMedia = [];

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
    // Useful for camera/gallery permissions handling
    if (state == AppLifecycleState.resumed) {
      // App resumed, check if permissions changed
    }
  }

  // Hàm tách riêng cho chụp ảnh - không thực hiện cắt ngay
  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Chỉ chụp ảnh, không cắt
      final result = await _mediaController.pickMedia(
        MediaOptions.camera(
          imageQuality: 90,
          // Bỏ cropOptions để tránh cắt ngay lập tức
        ),
      );

      // ignore: unnecessary_null_comparison
      if (result != null && result.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(result);
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chụp ảnh: $e')));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm tách riêng cho việc cắt ảnh
  Future<void> _cropSelectedImage(int index) async {
    if (index >= _selectedMedia.length ||
        _selectedMedia[index].type != MediaType.image) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Thêm delay nhỏ để đảm bảo UI đã cập nhật
      await Future.delayed(const Duration(milliseconds: 100));

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
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cắt ảnh: $e')));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Module Demo')),
      body: Column(
        children: [
          // Buttons for selecting media
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Button with options menu
                MediaPickerButton(
                  text: 'Chọn Media',
                  icon: Icons.add_photo_alternate,
                  options: const MediaOptions(
                    allowMultiple: true,
                    imageQuality: 80,
                    maxWidth: 1200,
                    maxHeight: 1200,
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
                  isLoading: _isLoading,
                ),

                // Camera button - Đã tách khỏi việc cắt
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Media preview grid
          Expanded(
            child:
                _selectedMedia.isEmpty
                    ? const Center(child: Text('Chưa có media nào được chọn'))
                    : GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            // Media preview
                            MediaPreview(
                              mediaItem: _selectedMedia[index],
                              borderRadius: BorderRadius.circular(8),
                              showDeleteButton: true,
                              onDelete: () {
                                setState(() {
                                  _selectedMedia.removeAt(index);
                                });
                              },
                            ),

                            // Edit button for images
                            if (_selectedMedia[index].type == MediaType.image)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.crop,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => _cropSelectedImage(index),
                                    constraints: const BoxConstraints.tightFor(
                                      width: 36,
                                      height: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
