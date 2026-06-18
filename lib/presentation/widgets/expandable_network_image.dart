import 'package:flutter/material.dart';

import 'network_image_preview.dart';

/// Miniatura de imagen de red con tap para abrir el visor expandido.
class ExpandableNetworkImage extends StatelessWidget {
  const ExpandableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.height = 56.0 * 1.3,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 10,
    this.backgroundColor,
    this.placeholder,
    this.hideWhenEmpty = false,
  });

  final String? imageUrl;
  final String heroTag;
  final double height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final bool hideWhenEmpty;

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      if (hideWhenEmpty) return const SizedBox.shrink();
      return _container(context, child: placeholder ?? const SizedBox.shrink());
    }

    final url = imageUrl!.trim();
    return _container(
      context,
      child: GestureDetector(
        onTap: () => showNetworkImagePreview(
          context,
          imageUrl: url,
          heroTag: heroTag,
        ),
        child: Hero(
          tag: heroTag,
          child: Image.network(
            url,
            fit: fit,
            width: width ?? double.infinity,
            height: height,
            errorBuilder: (context, error, stackTrace) =>
                placeholder ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _container(BuildContext context, {required Widget child}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
