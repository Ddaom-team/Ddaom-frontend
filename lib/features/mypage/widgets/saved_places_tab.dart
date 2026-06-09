import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class SavedPlacesTab extends StatelessWidget {
  const SavedPlacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '저장한 포토존이 없습니다.',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}