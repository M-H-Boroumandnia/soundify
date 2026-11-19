import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class CoverImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final IconData placeholderIcon;

  const CoverImage({
    super.key,
    required this.url,
    this.size = 52,
    this.radius = 8,
    this.placeholderIcon = Icons.music_note_rounded,
  });

  static final _googleSize = RegExp(r'=w\d+-h\d+');

  String _sizedUrl(String value, int px) {
    if (!value.contains('googleusercontent.com')) return value;
    final target = px.clamp(64, 544);
    return value.replaceFirst(_googleSize, '=w$target-h$target');
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        color: AppColors.textSecondary,
        size: size * 0.42,
      ),
    );
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final px = (size * ratio).round();
    final hasUrl = url != null && url!.isNotEmpty;
    final imageUrl = hasUrl ? _sizedUrl(url!, px) : null;
    final cachePx = hasUrl && imageUrl!.contains('googleusercontent.com')
        ? px.clamp(64, 544)
        : px;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: !hasUrl
            ? placeholder
            : Image(
                image: CachedNetworkImageProvider(
                  imageUrl!,
                  maxWidth: cachePx,
                  maxHeight: cachePx,
                ),
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, wasSyncLoaded) {
                  if (frame == null && !wasSyncLoaded) return placeholder;
                  return child;
                },
              ),
      ),
    );
  }
}
