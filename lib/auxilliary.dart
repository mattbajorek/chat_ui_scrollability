import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

const title = 'Chat UI Scrollability';

// ignore: constant_identifier_names
const Empty = SizedBox.shrink();

class CenteredProgressIndicator extends StatelessWidget {
  const CenteredProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(
          color: Colors.blue,
          constraints: BoxConstraints(minWidth: 20, maxWidth: 20, minHeight: 20, maxHeight: 20),
        ),
      ),
    );
  }
}

class SliverLoader extends StatelessWidget {
  final Key visibilityDetectorKey;
  final Function() onVisibilityChanged;

  const SliverLoader({required this.visibilityDetectorKey, required this.onVisibilityChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverVisibilityDetector(
      key: visibilityDetectorKey,
      onVisibilityChanged: (visibility) {
        if (visibility.visibleFraction > 0) {
          onVisibilityChanged();
        }
      },
      sliver: const SliverToBoxAdapter(child: CenteredProgressIndicator()),
    );
  }
}
