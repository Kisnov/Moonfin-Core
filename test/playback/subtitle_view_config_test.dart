import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:moonfin/playback/subtitle_view_config.dart';
import 'package:moonfin/preference/user_preferences.dart';
import 'package:playback_core/playback_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final store = PreferenceStore();
  await store.init();
  return UserPreferences(store);
}

StreamResolutionResult _resolution(List<Map<String, dynamic>> streams) =>
    StreamResolutionResult(
      streamUrl: 'https://host/stream',
      mediaSourceId: 'source',
      playMethod: StreamPlayMethod.directPlay,
      mediaStreams: streams,
    );

/// Runs [body] against a real BuildContext, which the config needs for the
/// screen height its bottom padding is measured against.
Future<void> _withContext(
  WidgetTester tester,
  void Function(BuildContext context) body,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          body(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Both players draw their subtitles through this, so what it hides and shows
  // is the difference between one set of subtitles on screen and two.
  testWidgets('a text subtitle is drawn by the subtitle view', (tester) async {
    final prefs = await _prefs();
    await _withContext(tester, (context) {
      final config = buildSubtitleViewConfiguration(
        context: context,
        prefs: prefs,
        resolution: _resolution([
          {'Index': 2, 'Codec': 'subrip'},
        ]),
        subtitleStreamIndex: 2,
      );
      expect(config.visible, isTrue);
    });
  });

  // ASS carries its own positioning and PGS is a bitmap, so the backend paints
  // those itself. Leaving the text view on would draw them a second time.
  testWidgets('a self-rendering subtitle hides the subtitle view', (
    tester,
  ) async {
    final prefs = await _prefs();
    await _withContext(tester, (context) {
      for (final codec in ['ass', 'pgssub']) {
        final config = buildSubtitleViewConfiguration(
          context: context,
          prefs: prefs,
          resolution: _resolution([
            {'Index': 2, 'Codec': codec},
          ]),
          subtitleStreamIndex: 2,
        );
        expect(config.visible, isFalse, reason: codec);
      }
    });
  });

  testWidgets('no selected subtitle leaves the view available', (tester) async {
    final prefs = await _prefs();
    await _withContext(tester, (context) {
      final config = buildSubtitleViewConfiguration(
        context: context,
        prefs: prefs,
        resolution: _resolution([
          {'Index': 2, 'Codec': 'ass'},
        ]),
        subtitleStreamIndex: null,
      );
      expect(config.visible, isTrue);
    });
  });

  // A live channel resolves without a stream list on its first tune, and the
  // config still has to come back rather than throw at the player.
  testWidgets('an unresolved stream still yields a config', (tester) async {
    final prefs = await _prefs();
    await _withContext(tester, (context) {
      final config = buildSubtitleViewConfiguration(
        context: context,
        prefs: prefs,
        resolution: null,
        subtitleStreamIndex: 2,
      );
      expect(config.visible, isTrue);
      expect(config.style.fontSize, greaterThan(0));
    });
  });
}
