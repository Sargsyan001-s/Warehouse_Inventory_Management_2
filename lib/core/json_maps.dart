// snake_case ↔ camelCase helpers for PostgREST rows.

Map<String, dynamic> snakeToCamel(Map<String, dynamic> row) {
  final out = <String, dynamic>{};
  row.forEach((key, value) {
    out[_toCamel(key)] = value;
  });
  return out;
}

String _toCamel(String snake) {
  final parts = snake.split('_');
  if (parts.length == 1) return snake;
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
          .join();
}

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

double asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
