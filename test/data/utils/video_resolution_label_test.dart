import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/utils/video_resolution_label.dart';

Map<String, dynamic> _stream(dynamic width, dynamic height, {bool? interlaced}) => {
  'Width': width,
  'Height': height,
  if (interlaced != null) 'IsInterlaced': interlaced,
};

void main() {
  group('videoResolutionLabel', () {
    test('names each step of the ladder', () {
      expect(videoResolutionLabel(_stream(7680, 4320)), '8K');
      expect(videoResolutionLabel(_stream(3840, 2160)), '4K');
      expect(videoResolutionLabel(_stream(2560, 1440)), '1440p');
      expect(videoResolutionLabel(_stream(1920, 1080)), '1080p');
      expect(videoResolutionLabel(_stream(1280, 720)), '720p');
      expect(videoResolutionLabel(_stream(854, 480)), '480p');
      // SD is the floor, so it has to fall under both thresholds: 640x360
      // still clears the 600 wide one and reads as 480p.
      expect(videoResolutionLabel(_stream(640, 360)), '480p');
      expect(videoResolutionLabel(_stream(320, 240)), 'SD');
    });

    // A scope film is letterboxed to fewer lines than its name suggests, so the
    // width alone has to be enough to earn the label.
    test('reads a letterboxed scope film by its width', () {
      expect(videoResolutionLabel(_stream(3840, 1600)), '4K');
      expect(videoResolutionLabel(_stream(1920, 800)), '1080p');
    });

    test('marks an interlaced stream, but not the fixed names above it', () {
      expect(videoResolutionLabel(_stream(1920, 1080, interlaced: true)), '1080i');
      expect(videoResolutionLabel(_stream(720, 576, interlaced: true)), '480i');
      expect(videoResolutionLabel(_stream(3840, 2160, interlaced: true)), '4K');
    });

    // A stream the server never probed carries a zero. Calling that SD invents
    // a fact rather than reading one, and the two copies of this ladder used to
    // disagree about it: the model answered SD, the detail screen answered
    // nothing.
    test('says nothing when the dimensions are unusable', () {
      expect(videoResolutionLabel(_stream(0, 0)), isNull);
      expect(videoResolutionLabel(_stream(1920, 0)), isNull);
      expect(videoResolutionLabel(_stream(-1, 1080)), isNull);
      expect(videoResolutionLabel(_stream(null, null)), isNull);
      expect(videoResolutionLabel(const {}), isNull);
    });

    // Servers do not agree on the type, and the copy that cast straight to int
    // would have thrown on anything else.
    test('takes dimensions however the server typed them', () {
      expect(videoResolutionLabel(_stream('1920', '1080')), '1080p');
      expect(videoResolutionLabel(_stream(1920.0, 1080.0)), '1080p');
      expect(videoResolutionLabel(_stream('not a number', 1080)), isNull);
    });
  });
}
