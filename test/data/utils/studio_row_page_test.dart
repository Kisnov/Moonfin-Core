import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/utils/studio_row_page.dart';

void main() {
  // A server holding [total] studios that, like Jellyfin, lists them by name
  // whatever sort it is asked for. Each call records the page and the sort.
  ({
    List<(int, int)> calls,
    List<String> sorts,
    Future<Map<String, dynamic>> Function(int, int, String, String) fetch,
  })
  server(int total) {
    final calls = <(int, int)>[];
    final sorts = <String>[];
    Future<Map<String, dynamic>> fetch(
      int startIndex,
      int limit,
      String sortBy,
      String sortOrder,
    ) async {
      calls.add((startIndex, limit));
      sorts.add('$sortBy $sortOrder');
      final end = (startIndex + limit).clamp(0, total);
      return {
        'Items': [
          for (var i = startIndex; i < end; i++) {'Id': '$i'},
        ],
        'TotalRecordCount': total,
      };
    }

    return (calls: calls, sorts: sorts, fetch: fetch);
  }

  Future<List<(int, int)>> pagesRead(
    int total, {
    required String sortBy,
    String sortOrder = 'Ascending',
    bool serverSorts = false,
    List<String>? sorts,
  }) async {
    final s = server(total);
    await fetchStudioRowPage(
      s.fetch,
      sortBy: sortBy,
      sortOrder: sortOrder,
      limit: 15,
      pageSize: 200,
      serverSorts: serverSorts,
    );
    sorts?.addAll(s.sorts);
    return s.calls;
  }

  test('name ascending reads just the row', () async {
    expect(await pagesRead(1000, sortBy: 'SortName'), [(0, 15)]);
  });

  test('name descending reads the end of the list', () async {
    expect(await pagesRead(1000, sortBy: 'SortName', sortOrder: 'Descending'), [
      (0, 200),
      (800, 200),
    ]);
  });

  test('random reads a page from anywhere in the list', () async {
    final calls = await pagesRead(1000, sortBy: 'Random');
    expect(calls, hasLength(2));
    expect(calls.last.$1, inInclusiveRange(0, 800));
    expect(calls.last.$2, 200);
  });

  test('date added sorts the first page', () async {
    expect(await pagesRead(1000, sortBy: 'DateCreated,SortName'), [(0, 200)]);
  });

  test('a list that fits in one page is read once', () async {
    expect(await pagesRead(120, sortBy: 'Random'), [(0, 200)]);
    expect(await pagesRead(120, sortBy: 'SortName', sortOrder: 'Descending'), [
      (0, 200),
    ]);
  });

  test('a server that sorts gets the sort and serves just the row', () async {
    final sorts = <String>[];
    expect(
      await pagesRead(
        1000,
        sortBy: 'DateCreated,SortName',
        sortOrder: 'Descending',
        serverSorts: true,
        sorts: sorts,
      ),
      [(0, 15)],
    );
    expect(sorts, ['DateCreated,SortName Descending']);
  });

  test('item count reads by name even from a server that sorts', () async {
    final sorts = <String>[];
    expect(
      await pagesRead(
        1000,
        sortBy: 'ItemCount',
        sortOrder: 'Descending',
        serverSorts: true,
        sorts: sorts,
      ),
      [(0, 200)],
    );
    expect(sorts, ['SortName Ascending']);
  });
}
