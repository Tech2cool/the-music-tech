import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SkeletonHorizontal extends StatelessWidget {
  final bool isLoading;
  final int length;

  const SkeletonHorizontal(
      {super.key, required this.isLoading, required this.length});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        itemCount: length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('Item number $index as title'),
              subtitle: const Text('Subtitle here'),
              leading: SizedBox(
                // width: 100,
                height: 80,
                child: Image.network(
                  "https://static-00.iconduck.com/assets.00/no-image-icon-512x512-lfoanl0w.png",
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
              trailing: const Icon(Icons.ac_unit),
            ),
          );
        },
      ),
    );
  }
}
