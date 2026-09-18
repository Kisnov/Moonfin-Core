import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/ui/screens/playback/video_surface_inset.dart';

/// Holding the video back from the camera housing. iOS reports the housing as a
/// horizontal inset in landscape, so nothing else is held back.
void main() {
  const landscape = EdgeInsets.only(left: 59, bottom: 21);
  const portrait = EdgeInsets.only(top: 59, bottom: 34);

  test('the setting off leaves the surface alone', () {
    expect(
      videoSurfaceInset(enabled: false, viewPadding: landscape),
      EdgeInsets.zero,
    );
  });

  test('landscape holds the picture back from the housing side only', () {
    expect(
      videoSurfaceInset(enabled: true, viewPadding: landscape),
      const EdgeInsets.only(left: 59),
    );
  });

  test('the housing on the other side is held back just the same', () {
    expect(
      videoSurfaceInset(
        enabled: true,
        viewPadding: const EdgeInsets.only(right: 59, bottom: 21),
      ),
      const EdgeInsets.only(right: 59),
    );
  });

  test('portrait is left alone, since the housing is above the picture', () {
    expect(
      videoSurfaceInset(enabled: true, viewPadding: portrait),
      EdgeInsets.zero,
    );
  });

  test('a screen with no housing is left alone', () {
    expect(
      videoSurfaceInset(enabled: true, viewPadding: EdgeInsets.zero),
      EdgeInsets.zero,
    );
  });
}
