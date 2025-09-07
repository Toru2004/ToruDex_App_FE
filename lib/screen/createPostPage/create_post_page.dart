import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:torudex/api/post_tag_api.dart';
import 'package:torudex/viewmodels/post_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:torudex/theme/theme_provider.dart';
import 'package:torudex/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/user_apis.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  String _usernameDisplay = "";
  final APIs _userApi = APIs();

  List<String> _availableTags = [];
  List<String> _selectedTags = [];
  final ValueNotifier<List<String>> _selectedTagsNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState(); 
    _fetchCurrentUserAvatar();
    loadTags();
    _selectedTagsNotifier.value = _selectedTags;
  }

  Future<void> loadTags() async {
    final tags = await PostTagApi.fetchAvailableTags();
    setState(() {
      _availableTags = tags;
    });
  }

  static const int maxImages = 10;

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= maxImages) {
        Get.snackbar(
          "Thông báo",
          "Bạn chỉ có thể chọn tối đa $maxImages ảnh",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final remainingSlots = maxImages - _selectedImages.length;
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        List<File> newImages = [];
        final imagesToAdd = pickedFiles.take(remainingSlots).toList();

        for (var pickedFile in imagesToAdd) {
          newImages.add(File(pickedFile.path));
        }

        setState(() {
          _selectedImages.addAll(newImages);
        });
        
        if (pickedFiles.length > remainingSlots) {
          Get.snackbar(
            "Thông báo",
            "Chỉ có thể thêm $remainingSlots ảnh nữa. Đã thêm ${imagesToAdd.length} ảnh.",
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      log('Error picking images: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chọn ảnh: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      if (_selectedImages.length >= maxImages) {
        Get.snackbar(
          "Thông báo",
          "Bạn chỉ có thể chọn tối đa $maxImages ảnh",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      log('Error capturing image: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chụp ảnh: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _fetchCurrentUserAvatar() async {
    setState(() => _isLoadingAvatar = true);
    final avatarUrl = await _userApi.getCurrentUserAvatarUrl();
    final username = await _userApi.getCurrentUsername();
    if (mounted) {
      setState(() {
        _fetchedUserAvatarUrl = avatarUrl;
        _usernameDisplay = username ?? "User";
        _isLoadingAvatar = false;
      });
    }
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (_selectedImages.length == 1)
            _buildSingleImage(_selectedImages[0], 0),
          if (_selectedImages.length >= 2)
            _buildMultipleImagesGrid(),
        ],
      ),
    );
  }

  Widget _buildSingleImage(File image, int index) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        ),
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => _removeImage(index),
        ),
      ],
    );
  }

  Widget _buildMultipleImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedImages.length == 2 ? 2 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length > 4 ? 4 : _selectedImages.length,
      itemBuilder: (context, index) {
        if (index == 3 && _selectedImages.length > 4) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImages[index],
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black54,
                ),
                child: Center(
                  child: Text(
                    '+${_selectedImages.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 12,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 12,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        elevation: 0,
        title: Text(
          'Bài đăng mới',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0), // Giảm khoảng cách với mép phải
            child: TextButton(
              onPressed: () async {
                await PostViewmodel().submitPost(
                  context,
                  _selectedImages,
                  _contentController.text.trim(),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Đăng',
                style: TextStyle(
                  color: AppTextStyles.buttonTextColor(isDarkMode),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Phần thông tin người dùng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: (_fetchedUserAvatarUrl != null && 
                                        _fetchedUserAvatarUrl!.isNotEmpty)
                            ? NetworkImage(_fetchedUserAvatarUrl!)
                            : null,
                        child: (_fetchedUserAvatarUrl == null || 
                                _fetchedUserAvatarUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey.shade700,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _usernameDisplay,
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(isDarkMode),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Hiển thị các tag đã chọn
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _selectedTagsNotifier,
                    builder: (context, tags, _) {
                      return tags.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.map((tag) {
                                  return Chip(
                                    label: Text(tag, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                                    onDeleted: () {
                                      _selectedTagsNotifier.value = 
                                        List.from(tags)..remove(tag);
                                      _selectedTags = 
                                        List.from(tags)..remove(tag);
                                    },
                                    deleteIcon: Icon(Icons.close, size: 16, color: AppIconStyles.iconPrimary(isDarkMode),),
                                    backgroundColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  
                  // Ô nhập nội dung
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode)
                          .withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    minLines: 1,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                  ),
                  
                  // Hiển thị ảnh đã chọn
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImageGrid(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_selectedImages.length}/$maxImages ảnh',
                            style: TextStyle(
                              color: AppTextStyles.subTextColor(isDarkMode),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedImages.length < maxImages)
                            TextButton(
                              onPressed: _pickImages,
                              child: Text(
                                'Thêm ảnh',
                                style: TextStyle(
                                  color: AppTextStyles.buttonTextColor(isDarkMode),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Thanh công cụ dưới cùng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: _selectedImages.length < maxImages
                        ? AppTextStyles.buttonTextColor(isDarkMode)
                        : AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  onPressed: _selectedImages.length < maxImages ? _pickImages : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    size: 28,
                    color: _selectedImages.length < maxImages
                        ? AppTextStyles.buttonTextColor(isDarkMode)
                        : AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  onPressed: _selectedImages.length < maxImages ? _captureImage : null,
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}