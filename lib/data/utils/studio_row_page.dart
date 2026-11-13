import 'dart:math';

import 'package:server_core/server_core.dart';

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

/// When each studio was last watched, by lower-case name, from the [limit]
/// most recently played movies and episodes. An episode counts for its series'
/// studio.
Future<Map<String, String>> fetchStudioLastPlayed(
  ItemsApi api, {
  int limit = 300,
}) async {
  final response = await api.getItems(
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
