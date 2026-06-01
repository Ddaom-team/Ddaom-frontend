import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../home_models.dart';
import '../home_provider.dart';

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final categories = PlaceCategory.values;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = provider.selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat.label),
            selected: selected,
            onSelected: (_) => provider.setCategory(cat),
            selectedColor: AppColors.primaryPink,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textMain,
              fontSize: 13,
            ),
          );
        },
      ),
    );
  }
}
