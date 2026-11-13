import 'dart:math';

/// Reads the studios a row sorted by [sortBy] and [sortOrder] is drawn from.
///
/// Jellyfin's /Studios ignores SortBy and SortOrder and always lists by name,
/// so any other order reads a wider page for the caller to sort.
Future<Map<String, dynamic>> fetchStudioRowPage(
  Future<Map<String, dynamic>> Function(int startIndex, int limit) fetchPage, {
  required String sortBy,
  required String sortOrder,
  required int limit,
  required int pageSize,
}) async {
  final byName = sortBy.split(',').first == 'SortName';
  final descending = sortOrder.toLowerCase() == 'descending';
  if (byName && !descending) return fetchPage(0, limit);
  final first = await fetchPage(0, pageSize);
  final lastStart = (first['TotalRecordCount'] as int? ?? 0) - pageSize;
  if (lastStart <= 0) return first;
  if (sortBy == 'Random') {
    return fetchPage(Random().nextInt(lastStart + 1), pageSize);
  }
  return byName ? fetchPage(lastStart, pageSize) : first;
}
