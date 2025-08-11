import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final Widget? child;
  final List<Widget>? children;

  const StatCard({
    super.key,
    required this.title,
    this.child,
    this.children,
  }) : assert(child == null || children == null,
            'Cannot provide both a child and children');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child ??
                Column(
                  children: children ?? [],
                ),
          ],
        ),
      ),
    );
  }
}
