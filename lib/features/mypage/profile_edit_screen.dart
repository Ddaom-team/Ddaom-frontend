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
  late String _originalName;
  String? _localAvatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<MyPageProvider>().profile;
    _originalName = profile?.name ?? '';
    _nameCtrl = TextEditingController(text: _originalName);
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

  Future<void> _save() async {
    final provider = context.read<MyPageProvider>();
    final newName = _nameCtrl.text.trim();
    setState(() => _saving = true);
    try {
      await Future.wait([
        if (newName.isNotEmpty && newName != _originalName)
          provider.updateNickname(newName),
        if (_localAvatarPath != null)
          provider.uploadProfileImage(_localAvatarPath!),
      ]);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPink,
                ),
              ),
            )
          else
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
              onTap: _saving ? null : _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!)) as ImageProvider
                        : (context.watch<MyPageProvider>().profile?.avatarUrl?.isNotEmpty ?? false)
                            ? NetworkImage(context.watch<MyPageProvider>().profile!.avatarUrl!)
                            : null,
                    backgroundColor: AppColors.illustrationBox,
                    child: (_localAvatarPath == null &&
                            (context.watch<MyPageProvider>().profile?.avatarUrl?.isEmpty ?? true))
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
