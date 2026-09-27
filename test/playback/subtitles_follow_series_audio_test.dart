import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/series_track_preference.dart';
import 'package:moonfin/data/services/log_service.dart';
import 'package:moonfin/data/services/media_server_client_factory.dart';
import 'package:moonfin/di/modules/playback_module.dart';
import 'package:moonfin/preference/preference_constants.dart';
import 'package:moonfin/preference/user_preferences.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Backend extends Fake implements PlayerBackend {
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => const Duration(minutes: 20);
  @override
  Duration get buffer => Duration.zero;
  @override
  bool get isPlaying => false;
  @override
  bool get isBuffering => false;
  @override
  double get playbackSpeed => 1.0;
  @override
  Stream<Duration> get positionStream => const Stream<Duration>.empty();
  @override
  Stream<Duration> get durationStream => const Stream<Duration>.empty();
  @override
  Stream<Duration> get bufferStream => const Stream<Duration>.empty();
  @override
  Stream<bool> get playingStream => const Stream<bool>.empty();
  @override
  Stream<bool> get bufferingStream => const Stream<bool>.empty();
  @override
  Stream<bool> get completedStream => const Stream<bool>.empty();
  @override
  Stream<Map<String, dynamic>>? get errorStream => null;
  @override
  bool get supportsRuntimeTrackSelection => true;
  @override
  bool get canRenderBitmapSubtitles => true;
  @override
  bool get requiresStartupMediaReadyCheck => false;
  @override
  bool get nativelyHandlesStartPosition => true;
  @override
  bool get demuxesEmbeddedSubtitles => true;

  @override
  Map<String, dynamic> getDeviceProfile({
    bool useProgressiveTranscode = false,
  }) => <String, dynamic>{};

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSubtitleTrack(
    int trackId, {
    bool isBitmapSubtitle = false,
    String? subtitleCodec,
    bool isExternalSubtitle = false,
    String? externalSubtitleUrl,
  }) async {}
  @override
  Future<void> disableSubtitleTrack() async {}
  @override
  Future<void> waitForTracksReady() async {}
  @override
  Future<void> waitForEmbeddedSubtitleCount(int count) async {}
  @override
  Future<void> setAudioTrack(int trackId) async {}
  @override
  Future<void> setSubtitleRendererMode(SubtitleRendererMode mode) async {}
  @override
  void dispose() {}
}

class _Resolver extends MediaStreamResolver {
  @override
  Future<StreamResolutionResult> resolve(
    dynamic mediaItem, {
    Map<String, dynamic>? deviceProfile,
    int? maxStreamingBitrate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    String? mediaSourceId,
    bool enableDirectPlay = true,
    bool enableDirectStream = true,
    bool enableTranscoding = true,
  }) async => const StreamResolutionResult(
    streamUrl: 'http://server/episode.mkv',
    mediaSourceId: 'source-1',
    playSessionId: 'session-1',
    playMethod: StreamPlayMethod.directPlay,
    mediaStreams: [
      {'Type': 'Audio', 'Index': 1, 'Language': 'eng', 'IsDefault': true},
      {'Type': 'Audio', 'Index': 2, 'Language': 'jpn'},
      {'Type': 'Subtitle', 'Index': 3, 'Language': 'eng', 'Codec': 'subrip'},
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    final store = PreferenceStore();
    await store.init();
    prefs = UserPreferences(store);
    const device = DeviceInfo(
      id: 'device',
      name: 'device',
      appName: 'Moonfin',
      appVersion: '1.0.0',
    );
    final clients = MediaServerClientFactory(deviceInfo: device);
    GetIt.instance
      ..registerSingleton<UserPreferences>(prefs)
      ..registerSingleton<MediaServerClientFactory>(clients)
      ..registerSingleton<LogService>(LogService(prefs, clients, device));

    // iOS builds the channel-only Aether backend, not media_kit.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    registerPlaybackModule();

    await prefs.set(UserPreferences.defaultAudioLanguage, 'eng');
    await prefs.set(UserPreferences.subtitleMode, SubtitleMode.foreign);
    await prefs.set(UserPreferences.defaultSubtitleLanguage, 'eng');
  });

  tearDown(() async {
    await GetIt.instance.reset();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<PlaybackManager> startEpisode() async {
    final backend = _Backend();
    final manager = GetIt.instance<PlaybackManager>()
      ..setBackend(backend)
      ..setBackendSelector((_, _) => backend)
      ..setResolverConfigurator((_) async {})
      ..setResolver(_Resolver());
    await manager.playItems([
      AggregatedItem(
        id: 'episode-1',
        serverId: 'server-1',
        rawData: const {
          'Id': 'episode-1',
          'Type': 'Episode',
          'SeriesId': 'series-1',
        },
      ),
    ]);
    return manager;
  }

  test('subtitles are picked for the remembered series audio', () async {
    await prefs.setSeriesAudioPreference(
      'series-1',
      const SeriesTrackPreference(language: 'jpn'),
    );

    final manager = await startEpisode();

    expect(manager.audioStreamIndex, 2);
    expect(manager.subtitleStreamIndex, 3);
  });

  test('subtitles stay off when the audio is the preferred language', () async {
    final manager = await startEpisode();

    expect(manager.audioStreamIndex, 1);
    expect(manager.subtitleStreamIndex, -1);
  });
}
