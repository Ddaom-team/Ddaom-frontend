// lib/features/place/place_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

class PlaceCreateScreen extends StatefulWidget {
  const PlaceCreateScreen({super.key});

  @override
  State<PlaceCreateScreen> createState() => _PlaceCreateScreenState();
}

class _PlaceCreateScreenState extends State<PlaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _category = '카페';
  bool _loading = false;

  static const _categories = ['카페', '식당', '팝업', '전시', '야경'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/api/places', data: {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'category': _category,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소가 등록되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 등록에 실패했습니다. 백엔드 API를 확인하세요.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 장소 등록'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: const Text('등록', style: TextStyle(color: AppColors.primaryPink,
              fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDeco('장소 이름'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '장소 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: _inputDeco('주소'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '주소를 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDeco('카테고리'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? '카페'),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
            else
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('장소 등록', style: TextStyle(color: Colors.white, fontSize: 16)),
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
