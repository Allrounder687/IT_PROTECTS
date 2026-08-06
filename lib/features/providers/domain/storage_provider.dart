abstract class StorageProvider {
  /// The unique identifier of this provider (e.g., 'google_drive', 'dropbox')
  String get providerId;

  /// Authenticate and retrieve OAuth tokens
  Future<void> authenticate({void Function(String url, String code)? onDeviceCodePrompt});

  /// Check if the user is authenticated
  Future<bool> isAuthenticated();

  /// Upload a chunk or an entire encrypted blob to the provider
  Future<void> uploadBlob(String fileId, List<int> encryptedBytes, {void Function(double)? onProgress});

  /// Download an encrypted blob from the provider
  Future<List<int>> downloadBlob(String fileId, {void Function(double)? onProgress});

  /// List all items currently stored in the remote vault folder
  Future<List<String>> listItems();

  /// Delete an encrypted blob from the provider
  Future<void> deleteItem(String fileId);

  /// Fetch the total and used quota of the user's cloud storage
  Future<Map<String, int>> getQuota();
}
