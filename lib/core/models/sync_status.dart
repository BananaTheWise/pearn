/// Represents the synchronisation state of a piece of data (e.g. a note).
///
/// Used by presenters and views to indicate whether the data is fully synced,
/// waiting to be pushed, or in an error state.
enum SyncStatus {
  /// The data is synchronised with the backend.
  synced,

  /// The data has local changes that have not yet been pushed.
  pending,

  /// The last synchronisation attempt failed.
  error,
}