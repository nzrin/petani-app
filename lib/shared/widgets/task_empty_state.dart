import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/empty_state_illustration.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({
    required this.description,
    this.title = 'Tiada Tugasan',
    this.imageSize = EmptyStateIllustration.defaultSize,
    this.topSpacing = EmptyStateIllustration.defaultTopSpacing,
    this.illustrationKey,
    this.action,
    super.key,
  });

  final String title;
  final String description;
  final double imageSize;
  final double topSpacing;
  final Key? illustrationKey;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyStateIllustration(
          key: illustrationKey,
          size: imageSize,
          topSpacing: topSpacing,
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (action case final action?) ...[const SizedBox(height: 20), action],
      ],
    );
  }
}
