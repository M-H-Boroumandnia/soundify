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

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: AppColors.textSecondary, size: size * 0.42),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: (size * 3).round(),
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
