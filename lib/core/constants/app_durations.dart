/// Centralized animation durations so motion feels consistent across
/// the entire app.
class AppDurations {
  AppDurations._();

  /// Total time the Splash Screen is displayed before navigating away.
  static const Duration splashTotal = Duration(seconds: 5);

  /// Duration used for page-to-page navigation transitions.
  static const Duration pageTransition = Duration(milliseconds: 550);

  /// Short duration used for small tap / press micro-interactions.
  static const Duration microInteraction = Duration(milliseconds: 220);
}
