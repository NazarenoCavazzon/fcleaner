import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:os_cleaner/os_cleaner.dart';
import 'package:ui/ui.dart';

class CleanupCategories extends StatelessWidget {
  const CleanupCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final analysisResult = homeCubit.state.cleanUpAnalysis;
    final categories = analysisResult.nonEmptyCategories
      ..sort(
        (a, b) => b.totalSize.compareTo(a.totalSize),
      );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleanup Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Select the categories you want to clean',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              late final int crossAxisCount;

              switch (constraints.maxWidth) {
                case >= 800:
                  crossAxisCount = 2;
                default:
                  crossAxisCount = 1;
              }

              return AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 8,
                itemCount: categories.length,
                itemBuilder: (context, index) =>
                    CleanupCategoryCard(categories[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CleanupCategoryCard extends StatelessWidget {
  const CleanupCategoryCard(
    this.category, {
    super.key,
  });

  final CleanupCategory category;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<HomeCubit, HomeState>(
            buildWhen: (previous, current) =>
                previous.selectedCategories[category.id] !=
                current.selectedCategories[category.id],
            builder: (context, state) {
              final isSelected = state.selectedCategories[category.id] ?? false;

              /// TODO: Add a custom checkbox widget
              return SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  value: isSelected,
                  onChanged: (value) =>
                      context.read<HomeCubit>().selectCategory(category.id),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      TextSpan(
                        text: ByteFormatter.format(category.totalSize),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: '  ${category.itemCount} items',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
