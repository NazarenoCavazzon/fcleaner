import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:fcleaner/home/widgets/cleanup_categories.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class SystemCleanupView extends StatelessWidget {
  const SystemCleanupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CleanupCategories(),
        const SizedBox(height: 16),
        MaterialButton(
          splashColor: Colors.transparent,
          focusElevation: 0,
          elevation: 0,
          highlightElevation: 0,
          hoverElevation: 0,
          disabledElevation: 0,
          highlightColor: Colors.transparent,
          minWidth: double.infinity,
          height: 64,
          color: false
              ? Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7)
              : Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: context.read<HomeCubit>().cleanUp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: false
                ? [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Analyzing your system...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                : [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Clean Up',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
