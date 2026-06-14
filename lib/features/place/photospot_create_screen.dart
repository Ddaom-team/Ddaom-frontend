import 'dart:convert';
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
  final _picker = ImagePicker();
  XFile? _image;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대표 사진을 선택해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_image!.path,
            filename: 'photospot.jpg'),
        'request': MultipartFile.fromString(
          jsonEncode({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
          }),
          contentType: DioMediaType('application', 'json'),
        ),
      });
      await api.dio
          .post('/api/places/${widget.placeId}/photospots', data: formData);
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
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('대표 사진 선택',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_image!.path),
                            width: double.infinity, fit: BoxFit.cover),
                      ),
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
