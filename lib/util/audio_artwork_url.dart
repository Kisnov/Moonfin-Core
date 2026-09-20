import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../data/models/aggregated_item.dart';
import '../data/services/media_server_client_factory.dart';

/// The artwork for the track that is playing, at the size the surface wants.
///
/// A music track shows its album's cover rather than its own picture, and
/// anything else shows its own. Every surface that draws the current track --
/// the mini player, the sidebar, the toolbar, the tvOS now playing card, the
/// desktop MPRIS card -- asks this, so none of them can end up showing a
/// different picture for the same track.
///
/// [maxHeight] is the only thing that legitimately differs between them, so it
/// is the only thing they pass. A surface whose fetch leaves the app's auth
/// header behind wraps the result itself; see `tokenAuthedUrl`.
///
/// Returns null when the item carries no artwork, and when the server it came
/// from can no longer be reached to build a url against.
String? audioArtUrl(
  AggregatedItem item, {
  required MediaServerClientFactory clientFactory,
  required int maxHeight,
}) {
  try {
    final client = clientFactory.getClientIfExists(item.serverId) ??
        GetIt.instance<MediaServerClient>();
    final albumTag = item.albumPrimaryImageTag;
    final albumId = item.albumId;
    if (item.type == 'Audio' && albumTag != null && albumId != null) {
      return client.imageApi
          .getPrimaryImageUrl(albumId, maxHeight: maxHeight, tag: albumTag);
    }
    if (item.primaryImageTag != null) {
      return client.imageApi
          .getPrimaryImageUrl(item.id, maxHeight: maxHeight, tag: item.primaryImageTag);
    }
  } catch (_) {}
  return null;
}
