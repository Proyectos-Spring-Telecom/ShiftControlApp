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
    this.loadingMessage = 'Cargando imagen...',
    this.errorMessage = 'No se pudo cargar la imagen',
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
  final String loadingMessage;
  final String errorMessage;

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
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _loadingPlaceholder(context, loadingProgress);
            },
            errorBuilder: (context, error, stackTrace) {
              if (placeholder != null) return placeholder!;
              return _errorPlaceholder(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _loadingPlaceholder(
    BuildContext context,
    ImageChunkEvent loadingProgress,
  ) {
    final expected = loadingProgress.expectedTotalBytes;
    final loaded = loadingProgress.cumulativeBytesLoaded;
    final hasProgress = expected != null && expected > 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: hasProgress
                ? CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: loaded / expected,
                    color: _accentColor(context),
                  )
                : CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _accentColor(context),
                  ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              loadingMessage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: _mutedTextColor(context),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _mutedTextColor(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _mutedTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.45);
  }

  Color _accentColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
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
