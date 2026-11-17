class Paginated<T> {
  final int count;
  final bool hasNext;
  final List<T> results;

  const Paginated({
    required this.count,
    required this.hasNext,
    required this.results,
  });

  static List<Map<String, dynamic>> extractList(dynamic data) {
    dynamic raw = data;
    if (raw is Map) {
      raw = raw['results'] ?? raw['items'] ?? raw['data'] ?? const [];
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  factory Paginated.fromJson(
    dynamic data,
    T Function(Map<String, dynamic>) parse,
  ) {
    final items = extractList(data).map(parse).toList();
    if (data is Map) {
      return Paginated(
        count: (data['count'] as num?)?.toInt() ?? items.length,
        hasNext: data['next'] != null,
        results: items,
      );
    }
    return Paginated(count: items.length, hasNext: false, results: items);
  }
}
