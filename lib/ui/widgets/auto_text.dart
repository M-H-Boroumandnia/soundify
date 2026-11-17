import 'package:material_ui/material_ui.dart';

TextDirection detectDirection(String text) {
  for (final rune in text.runes) {
    if ((rune >= 0x0590 && rune <= 0x08FF) || (rune >= 0xFB1D && rune <= 0xFEFC)) {
      return TextDirection.rtl;
    }
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A) || rune >= 0xC0) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.rtl;
}

class AutoText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  const AutoText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final appRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textDirection: detectDirection(text),
      textAlign: textAlign ?? (appRtl ? TextAlign.right : TextAlign.left),
    );
  }
}
