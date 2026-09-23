import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Avatar circular con anillo de gradiente de marca.
/// Si no hay foto, muestra las iniciales sobre un tono pastel.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.tintIndex = 0,
    this.photoUrl,
    this.ringWidth = 2.5,
  });

  final String initials;
  final double size;
  final int tintIndex;

  /// Ruta de asset (`assets/...`) o URL de red.
  final String? photoUrl;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.avatarTints[tintIndex % AppColors.avatarTints.length];
    final initialsText = Center(
      child: Text(
        initials,
        style: AppTypography.label.copyWith(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w600,
          color: AppColors.purple,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: ClipOval(
          child: ColoredBox(
            color: tint,
            child: photoUrl == null
                ? initialsText
                : SizedBox.expand(child: _photo(photoUrl!, initialsText)),
          ),
        ),
      ),
    );
  }

  /// Los retratos suelen tener la cara en el tercio superior,
  /// por eso se alinea un poco hacia arriba.
  Widget _photo(String path, Widget fallback) {
    const alignment = Alignment(0, -0.45);
    Widget onError(BuildContext _, Object _, StackTrace? _) => fallback;
    final image = path.startsWith('assets/')
        ? Image.asset(path, fit: BoxFit.cover, alignment: alignment, errorBuilder: onError)
        : Image.network(path, fit: BoxFit.cover, alignment: alignment, errorBuilder: onError);
    // Acerca un poco la foto para que el rostro llene el círculo.
    return Transform.scale(scale: 1.25, alignment: const Alignment(0, -0.6), child: image);
  }
}
