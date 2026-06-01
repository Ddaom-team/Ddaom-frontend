import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../place_provider.dart';

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<PlaceProvider>().detail?.reviews ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (_, i) => const Divider(height: 24),
      itemBuilder: (context, i) {
        final r = reviews[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(r.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(
                    5,
                    (j) => Icon(
                      j < r.rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(r.content,
                style: const TextStyle(fontSize: 13, color: AppColors.textMain)),
          ],
        );
      },
    );
  }
}
