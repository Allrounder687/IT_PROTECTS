import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static bool _googleSignInInitialized = false;

  Future<void> _initGoogleSignInIfNeeded() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: Platform.isIOS 
            ? '100219501471-7bq2p5l3j7vid9uuhr6e3ab4dgf3u7mh.apps.googleusercontent.com'
            : null,
      );
      _googleSignInInitialized = true;
    }
  }

  // For Windows / TV Device Flow
  final _desktopClientId = auth_io.ClientId(
    '100219501471-vccc1k06b9tjcal4' 'd5mjot4s6kfhm8ti.apps.googleusercontent.com',
    'GOCSPX-8I' 'pqpCOrd_0fvxLDasRkdgCyTmiy',
  );
  
  final _tvClientId = auth_io.ClientId(
    '100219501471-b1muhb7s8ihs1e3pi' '2vlga5pc9aop3mt.apps.googleusercontent.com',
    'GOCSPX-4g' '6uVlLMJrRpPg3b5r0yjKSeDSil',
  );

  auth_io.AutoRefreshingAuthClient? _desktopClient;

  @override
  Future<void> authenticate({void Function(String url, String code)? onDeviceCodePrompt}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _initGoogleSignInIfNeeded();
      final account = await GoogleSignIn.instance.authenticate();
      if (account == null) throw Exception("User canceled sign in");
      
      final clientAuth = await account.authorizationClient.authorizeScopes([drive.DriveApi.driveAppdataScope]);
      final accessToken = clientAuth.accessToken;
      if (accessToken == null) throw Exception("User did not grant drive scope");

      final authHeaders = {
        'Authorization': 'Bearer $accessToken',
        'X-Goog-AuthUser': '0',
      };
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
    } else {
      // Windows / macOS / Linux / TV using Consent Flow
      final clientId = Platform.isWindows ? _desktopClientId : _tvClientId;
      
      final client = http.Client();
      try {
        _desktopClient = await auth_io.clientViaUserConsent(
          clientId,
          [drive.DriveApi.driveAppdataScope],
          (url) {
            if (onDeviceCodePrompt != null) {
              onDeviceCodePrompt(url, "code");
            }
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
              url_launcher.launchUrl(Uri.parse(url));
            }
          },
        );
        
        // Save credentials
        final creds = _desktopClient!.credentials;
        final jsonStr = jsonEncode({
          'accessToken': creds.accessToken.data,
          'type': creds.accessToken.type,
          'expiry': creds.accessToken.expiry.toIso8601String(),
          'refreshToken': creds.refreshToken,
          'scopes': creds.scopes,
        });
        await _secureStorage.write(key: 'google_drive_credentials', value: jsonStr);
        
        _driveApi = drive.DriveApi(_desktopClient!);
      } catch (e) {
        client.close();
        rethrow;
      }
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await _initGoogleSignInIfNeeded();
        final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (account == null) return false;
        
        final clientAuth = await account.authorizationClient.authorizationForScopes([drive.DriveApi.driveAppdataScope]);
        final accessToken = clientAuth?.accessToken;
        if (accessToken == null) return false;
        
        final authHeaders = {
          'Authorization': 'Bearer $accessToken',
          'X-Goog-AuthUser': '0',
        };
        final authenticateClient = GoogleAuthClient(authHeaders);
        _driveApi = drive.DriveApi(authenticateClient);
        return true;
      } catch (_) {
        return false;
      }
    } else {
      if (_desktopClient != null) return true;
      
      final savedCredsStr = await _secureStorage.read(key: 'google_drive_credentials');
      if (savedCredsStr != null) {
        try {
          final map = jsonDecode(savedCredsStr);
          final credentials = auth_io.AccessCredentials(
            auth_io.AccessToken(map['type'], map['accessToken'], DateTime.parse(map['expiry']).toUtc()),
            map['refreshToken'],
            List<String>.from(map['scopes']),
          );
          
          final clientId = Platform.isWindows ? _desktopClientId : _tvClientId;
          _desktopClient = auth_io.autoRefreshingClient(clientId, credentials, http.Client());
          _driveApi = drive.DriveApi(_desktopClient!);
          return true;
        } catch (_) {
          await _secureStorage.delete(key: 'google_drive_credentials');
          return false;
        }
      }
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
