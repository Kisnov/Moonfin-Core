import 'dart:math';

import 'package:server_core/server_core.dart';

/// Reads the studios a row sorted by [sortBy] and [sortOrder] is drawn from.
///
/// A server that [serverSorts] gets the sort, and its first page is the row.
/// Otherwise, and for item count and last played, which no server sorts
/// studios by, the row reads a wider page by name for the caller to sort.
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
  final rankedInApp =
      sortBy == 'ItemCount' || sortBy.startsWith('DatePlayed');
  if (serverSorts && !rankedInApp) {
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

/// When each studio was last watched, by lower-case name, from the [limit]
/// most recently played movies and episodes in [parentId], or in every library.
/// An episode counts for its series' studio.
Future<Map<String, String>> fetchStudioLastPlayed(
  ItemsApi api, {
  String? parentId,
  int limit = 300,
}) async {
  final response = await api.getItems(
    parentId: parentId,
    recursive: true,
    includeItemTypes: const ['Movie', 'Episode'],
    sortBy: 'DatePlayed',
    sortOrder: 'Descending',
    limit: limit,
    fields: 'Studios,SeriesStudio,UserData',
  );
  final lastPlayed = <String, String>{};
  for (final item
      in (response['Items'] as List? ?? const [])
          .cast<Map<String, dynamic>>()) {
    final date = (item['UserData'] as Map?)?['LastPlayedDate'] as String?;
    if (date == null) continue;
    final names = [
      for (final studio in item['Studios'] as List? ?? const [])
        (studio as Map)['Name'],
      item['SeriesStudio'],
    ];
    for (final name in names.whereType<String>()) {
      lastPlayed.putIfAbsent(name.toLowerCase(), () => date);
    }
  }
  return lastPlayed;
}

/// Puts each studio's date from [lastPlayed] in its UserData, where
/// sortAggregatedItems reads it.
void markStudiosLastPlayed(
  Iterable<Map<String, dynamic>> studios,
  Map<String, String> lastPlayed,
) {
  for (final studio in studios) {
    final date = lastPlayed[(studio['Name'] as String? ?? '').toLowerCase()];
    if (date == null) continue;
    studio['UserData'] = {
      ...?studio['UserData'] as Map<String, dynamic>?,
      'LastPlayedDate': date,
    };
  }
}
