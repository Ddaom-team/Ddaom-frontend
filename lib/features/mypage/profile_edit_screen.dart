import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'mypage_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameCtrl;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    final profile = context.read<MyPageProvider>().profile;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _localAvatarPath = file.path);
  }

  void _save() {
    context.read<MyPageProvider>().updateProfile(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      avatarUrl: _localAvatarPath,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('완료', style: TextStyle(color: AppColors.primaryPink)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!))
                        : null,
                    backgroundColor: AppColors.illustrationBox,
                    child: _localAvatarPath == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.textMuted)
                        : null,
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryPink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
