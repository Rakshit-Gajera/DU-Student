import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'common.dart';
import 'demo_data.dart';
import 'ui_kit.dart';

/// Skeleton while loading, an error card with retry on failure, otherwise [builder].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.onRetry, required this.builder, this.skeleton = const SkeletonList()});
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final Widget skeleton;

  @override
  Widget build(BuildContext context) {
    // A retry keeps the old error on the value, so check loading first.
    if (value.isLoading && (value.hasError || !value.hasValue)) return skeleton;
    if (value.hasError) return ErrorCard(error: value.error!, onRetry: onRetry);
    return builder(value.requireValue);
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException ? (error as ApiException).message : 'Something went wrong while loading this page.';
    return Center(
      child: Container(
        key: const Key('error-card'),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(shadow: true),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 34, color: AppColors.red),
          const SizedBox(height: 8),
          Text('Could not load', style: hv(17)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: bd(13.6, const Color(0xFF555555))),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('retry'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

/// Grey cards that gently pulse.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 6, this.height = 84, this.padding = const EdgeInsets.fromLTRB(10, 10, 10, 0)});
  final int count;
  final double height;
  final EdgeInsets padding;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        key: const Key('skeleton'),
        opacity: Tween<double>(begin: .45, end: 1).animate(_pulse),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.count,
          itemBuilder: (_, _) => Container(
            height: widget.height,
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(kRadius)),
          ),
        ),
      );
}

/// A student's photo. Uses the bundled picture when there is none, or it fails to load.
class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({super.key, this.url, required this.radius});
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = url;
    if (photo == null || photo.isEmpty) return CircleAvatar(radius: radius, backgroundImage: const AssetImage(demoPhoto));
    return CircleAvatar(
      radius: radius,
      backgroundImage: const AssetImage(demoPhoto),
      foregroundImage: NetworkImage(resolveApiUrl(photo)),
      onForegroundImageError: (_, _) {},
    );
  }
}
