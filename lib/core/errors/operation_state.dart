/// Coarse-grained state of an asynchronous operation exposed by a view model.
///
/// Replaces the single `bool isLoading` (review claim 2.3): one boolean could
/// not tell apart the first load (no data yet) from a background refresh (keep
/// showing the data we already have) from a mutation (block double-submission)
/// from a terminal error.
///
/// Convention for every view model in the app:
/// - exposes [state] (this enum) instead of `isLoading`;
/// - exposes `String? errorMessage` — set iff [error];
/// - exposes `bool get isBusy` as a shorthand for "any in-flight state", used
///   to disable buttons and FABs.
///
/// The pair ([error], `errorMessage`) is the only error channel: a view model
/// never swallows an exception silently. Mapped messages come from
/// [mapExceptionToMessage].
enum OperationState {
  /// Nothing launched yet. Screens show a placeholder/skeleton.
  idle,

  /// First load, no data available. Screens show a spinner / empty state.
  loading,

  /// Reload with data already on screen. Existing data MUST be preserved while
  /// refreshing — the screen keeps showing it with a discreet indicator. This
  /// is what stops the "screen blanks during a reload" bug.
  refreshing,

  /// A mutation is in flight. Mutations are ignored while this state is active
  /// (claim 2.3 — double-submit guard).
  mutating,

  /// Stable success state with data.
  success,

  /// The last load failed. `errorMessage` is populated; screens show an inline
  /// error state. Existing data, if any, is left untouched.
  error,
}
