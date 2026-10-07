import 'package:flutter/material.dart';

/// Текст с обрезкой длинных названий.
class EllipsisText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int maxLines;

  const EllipsisText(this.data, {super.key, this.style, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
    );
  }
}
