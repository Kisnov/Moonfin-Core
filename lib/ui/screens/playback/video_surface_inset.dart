import 'package:flutter/widgets.dart';

/// How far to hold the video back from the camera housing.
///
/// iOS reports the housing as a horizontal inset in landscape, so those are the
/// only sides worth holding back. Doing it to the surface is enough on its own:
/// a picture the screen is already wider than keeps its size, and one that
/// reached the housing shrinks by exactly what it takes to clear it.
EdgeInsets videoSurfaceInset({
  required bool enabled,
  required EdgeInsets viewPadding,
}) {
  if (!enabled) return EdgeInsets.zero;
  return EdgeInsets.only(left: viewPadding.left, right: viewPadding.right);
}
