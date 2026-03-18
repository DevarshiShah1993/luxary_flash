/// Represents the status of the background isolate parse job.
/// Emitted by the BLoC state so the UI can show a loading indicator
/// while the heavy work runs off-thread.
enum ParseStatus {
  /// Isolate has not been spawned yet.
  idle,

  /// Isolate is running — UI should show a loading spinner.
  parsing,

  /// Isolate returned successfully — [List<BidPoint>] is ready.
  complete,

  /// Isolate threw an exception.
  failed,
}
