import 'package:flutter/material.dart';

class NetImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final Widget? placeholder;
  final Widget? fallback;

  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (ctx, child, evt) {
        if (evt == null) return child;
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (ctx, err, stack) =>
          fallback ??
          Container(
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 20),
          ),
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: img)
        : img;
  }
}
