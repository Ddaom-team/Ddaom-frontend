import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../place_models.dart';
import '../place_provider.dart';
import 'photozone_card.dart';
import '../photospot_create_screen.dart';

class PhotozoneTab extends StatelessWidget {
  const PhotozoneTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final tags = [null, ...provider.availableTags];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final p = context.read<PlaceProvider>();
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PhotoSpotCreateScreen(placeId: p.placeId),
                  ),
                );
                if (created == true) p.reload();
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('포토존 등록'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPink),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: tags.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = tags[i];
              final selected = provider.selectedTag == tag;
              return ChoiceChip(
                label: Text(tag == null ? '전체' : tag.label),
                selected: selected,
                onSelected: (_) => provider.setTag(tag),
                selectedColor: AppColors.primaryPink,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textMain,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.filteredZones.length,
            separatorBuilder: (_, i) => const Divider(height: 24),
            itemBuilder: (context, i) => PhotozoneCard(zone: provider.filteredZones[i]),
          ),
        ),
      ],
    );
  }
}
