int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// The resolution badge for a video stream, read off its dimensions.
///
/// The thresholds sit below each nominal size on purpose: a scope-ratio film is
/// letterboxed to fewer lines than its name suggests, and a stream cropped a
/// few pixels either way is still the resolution it is sold as.
///
/// Returns null when the server gave no usable dimensions. Some libraries carry
/// a zero width or height on a stream that was never probed, and calling that
/// SD would be inventing a fact rather than reading one.
String? videoResolutionLabel(Map<String, dynamic> stream) {
  final width = _toInt(stream['Width']);
  final height = _toInt(stream['Height']);
  if (width == null || height == null || width <= 0 || height <= 0) return null;

  final suffix = stream['IsInterlaced'] == true ? 'i' : 'p';

  if (width >= 7600 || height >= 4300) return '8K';
  if (width >= 3800 || height >= 2000) return '4K';
  if (width >= 2500 || height >= 1400) return '1440$suffix';
  if (width >= 1800 || height >= 1000) return '1080$suffix';
  if (width >= 1200 || height >= 700) return '720$suffix';
  if (width >= 600 || height >= 400) return '480$suffix';
  return 'SD';
}
