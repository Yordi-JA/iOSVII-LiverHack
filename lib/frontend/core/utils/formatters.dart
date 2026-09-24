/// Formatea montos en MXN de forma compacta: 1200000 → $1.2M, 850000 → $850k.
String formatMoney(num value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    final text = millions == millions.roundToDouble()
        ? millions.toStringAsFixed(0)
        : millions.toStringAsFixed(1);
    return '\$${text}M';
  }
  return '\$${(value / 1000).round()}k';
}

/// Como [formatMoney] pero con hasta dos decimales sin ceros sobrantes:
/// 1250000 → $1.25M, 1200000 → $1.2M, 950000 → $950k.
String formatMoneyShort(num value) {
  if (value >= 1000000) {
    final text = (value / 1000000).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '\$${text}M';
  }
  return '\$${(value / 1000).round()}k';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
}
