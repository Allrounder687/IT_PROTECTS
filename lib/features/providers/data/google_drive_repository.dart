import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../domain/storage_provider.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveRepository implements StorageProvider {
  @override
  String get providerId => 'google_drive';
  
  drive.DriveApi? _driveApi;

  @override
  Future<void> authenticate() async {
    final account = await GoogleSignIn.instance.authenticate();
    
    final authz = await account.authorizationClient.authorizationForScopes([drive.DriveApi.driveAppdataScope]);
    if (authz == null) throw Exception("Failed to get token");
    
    final authHeaders = {'Authorization': 'Bearer ${authz.accessToken}'};
    
    final authenticateClient = GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(authenticateClient);
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account == null) return false;
      
      final authz = await account.authorizationClient.authorizationForScopes([drive.DriveApi.driveAppdataScope]);
      if (authz == null) return false;
      
      final authHeaders = {'Authorization': 'Bearer ${authz.accessToken}'};
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> uploadBlob(String fileId, List<int> encryptedBytes, {void Function(double)? onProgress}) async {
    if (_driveApi == null) throw Exception("Not authenticated");
    
    final media = drive.Media(Stream.value(encryptedBytes), encryptedBytes.length);
    final driveFile = drive.File()
      ..name = '$fileId.enc'
      ..parents = ['appDataFolder'];
    
    await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
    );
  }

  @override
  Future<List<int>> downloadBlob(String fileId, {void Function(double)? onProgress}) async {
    if (_driveApi == null) throw Exception("Not authenticated");
    
    final fileList = await _driveApi!.files.list(
      spaces: 'appDataFolder',
      q: "name='$fileId.enc'",
    );
    
    if (fileList.files == null || fileList.files!.isEmpty) {
      throw Exception("File not found on Drive");
    }
    
    final driveFileId = fileList.files!.first.id!;
    
    final drive.Media media = await _driveApi!.files.get(
      driveFileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    
    List<int> bytes = [];
    await for (var chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  @override
  Future<List<String>> listItems() async {
    if (_driveApi == null) throw Exception("Not authenticated");
    
    final fileList = await _driveApi!.files.list(
      spaces: 'appDataFolder',
    );
    
    return fileList.files?.map((f) => f.name ?? '').where((n) => n.endsWith('.enc')).toList() ?? [];
  }

  @override
  Future<void> deleteItem(String fileId) async {
    if (_driveApi == null) throw Exception("Not authenticated");
    
    final fileList = await _driveApi!.files.list(
      spaces: 'appDataFolder',
      q: "name='$fileId.enc'",
    );
    
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final driveFileId = fileList.files!.first.id!;
      await _driveApi!.files.delete(driveFileId);
    }
  }

  @override
  Future<Map<String, int>> getQuota() async {
    if (_driveApi == null) throw Exception("Not authenticated");
    
    final about = await _driveApi!.about.get($fields: 'storageQuota');
    final quota = about.storageQuota;
    
    return {
      'total': int.tryParse(quota?.limit ?? '0') ?? 0,
      'used': int.tryParse(quota?.usage ?? '0') ?? 0,
    };
  }
}
