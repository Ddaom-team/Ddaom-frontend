import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

class PhotoSpotCreateScreen extends StatefulWidget {
  final String placeId;
  const PhotoSpotCreateScreen({super.key, required this.placeId});

  @override
  State<PhotoSpotCreateScreen> createState() => _PhotoSpotCreateScreenState();
}

class _PhotoSpotCreateScreenState extends State<PhotoSpotCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _pickedImage;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _pickedImage = picked);
    }
  }

  /// 선택한 사진을 S3 업로드 API로 올리고 imageUrl을 받는다.
  Future<String> _uploadImage(ApiClient api, XFile image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final res = await api.dio.post('/api/uploads/images', data: formData);
    return (res.data as Map<String, dynamic>)['imageUrl'] as String;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      // 사진을 골랐으면 먼저 S3에 업로드해 imageUrl을 받고, 포토존 생성에 함께 전송.
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(api, _pickedImage!);
      }
      await api.dio.post(
        '/api/places/${widget.placeId}/photo-spots',
        data: {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'imageUrl': ?imageUrl,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포토존이 등록되었습니다.')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = (code == 404 || code == 501)
          ? '포토존 등록 API가 아직 준비 중입니다.'
          : '포토존 등록에 실패했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포토존 등록'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: const Text('등록',
                style: TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _loading ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: _pickedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text('대표 사진 추가 (선택)',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDeco('포토존 이름'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '포토존 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _inputDeco('설명 (선택)'),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryPink))
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('포토존 등록',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryPink),
        ),
      );
}
