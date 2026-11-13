import 'dart:math';

/// Reads the studios a row sorted by [sortBy] and [sortOrder] is drawn from.
///
/// A server that [serverSorts] gets the sort, and its first page is the row.
/// Otherwise, and for item count, which no server sorts studios by, the row
/// reads a wider page by name for the caller to sort.
Future<Map<String, dynamic>> fetchStudioRowPage(
  Future<Map<String, dynamic>> Function(
    int startIndex,
    int limit,
    String sortBy,
    String sortOrder,
  )
  fetchPage, {
  required String sortBy,
  required String sortOrder,
  required int limit,
  required int pageSize,
  required bool serverSorts,
}) async {
  if (serverSorts && sortBy != 'ItemCount') {
    return fetchPage(0, limit, sortBy, sortOrder);
  }
  Future<Map<String, dynamic>> byName(int startIndex, int limit) =>
      fetchPage(startIndex, limit, 'SortName', 'Ascending');
  final nameSort = sortBy.split(',').first == 'SortName';
  final descending = sortOrder.toLowerCase() == 'descending';
  if (nameSort && !descending) return byName(0, limit);
  final first = await byName(0, pageSize);
  final lastStart = (first['TotalRecordCount'] as int? ?? 0) - pageSize;
  if (lastStart <= 0) return first;
  if (sortBy == 'Random') {
    return byName(Random().nextInt(lastStart + 1), pageSize);
  }
  return nameSort ? byName(lastStart, pageSize) : first;
}
