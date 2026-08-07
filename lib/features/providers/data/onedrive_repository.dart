import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/storage_provider.dart';

class OneDriveRepository implements StorageProvider {
  @override
  String get providerId => 'onedrive';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _clientId = '4fc11832-e73d-4106-adc8-2c9f26668c57';
  static const String _redirectUrl = 'com.syeds.itprotects://oauthredirect';
  static const String _authorizationEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String _tokenEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';

  String? _accessToken;

  @override
  Future<void> authenticate({void Function(String url, String code)? onDeviceCodePrompt}) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: true);
        final String loopbackUrl = 'http://localhost:${server.port}/';
        
        final authUrl = Uri.parse(_authorizationEndpoint).replace(queryParameters: {
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': loopbackUrl,
          'scope': 'Files.ReadWrite.AppFolder offline_access',
        });
        
        String? code;
        try {
          await launchUrl(authUrl);
          
          await for (var request in server) {
            code = request.uri.queryParameters['code'];
            if (code != null) {
              request.response
                ..statusCode = 200
                ..headers.contentType = ContentType.html
                ..write('<html><body style="font-family:sans-serif; text-align:center; padding:50px;"><h2>Success!</h2><p>You can close this window and return to IT Protects.</p></body></html>');
              await request.response.close();
              break;
            } else {
              request.response
                ..statusCode = 400
                ..headers.contentType = ContentType.html
                ..write('<html><body><h2>Waiting for redirect...</h2></body></html>');
              await request.response.close();
            }
          }
        } finally {
          await server.close(force: true);
        }
        
        if (code == null) {
          throw Exception("Authorization code not found in redirect");
        }
        
        final tokenResponse = await http.post(
          Uri.parse(_tokenEndpoint),
          body: {
            'code': code,
            'grant_type': 'authorization_code',
            'client_id': _clientId,
            'redirect_uri': loopbackUrl,
          }
        );
        
        if (tokenResponse.statusCode == 200) {
          final data = jsonDecode(tokenResponse.body);
          _accessToken = data['access_token'];
          await _secureStorage.write(key: 'onedrive_access_token', value: _accessToken);
        } else {
          throw Exception("Failed to exchange code: ${tokenResponse.body}");
        }
      } else {
        print('[OAuth Diagnostic - OneDrive] Starting authorization for $_clientId...');
        final startTime = DateTime.now();
        print('[OAuth Diagnostic - OneDrive] Redirect URI configured: $_redirectUrl');

        final AuthorizationResponse? authResult = await _appAuth.authorize(
          AuthorizationRequest(
            _clientId,
            _redirectUrl,
            serviceConfiguration: const AuthorizationServiceConfiguration(
              authorizationEndpoint: _authorizationEndpoint,
              tokenEndpoint: _tokenEndpoint,
            ),
            scopes: ['Files.ReadWrite.AppFolder', 'offline_access'],
          ),
        );

        if (authResult == null) {
          throw Exception("Authorization was cancelled or failed to return a response.");
        }

        print('[OAuth Diagnostic - OneDrive] Callback received at: ${DateTime.now().difference(startTime).inSeconds}s');
        print('[OAuth Diagnostic - OneDrive] Auth Code present: ${authResult.authorizationCode != null}');

        if (authResult.authorizationCode == null) {
          throw Exception("Authorization callback did not contain a code.");
        }

        print('[OAuth Diagnostic - OneDrive] Proceeding to token exchange...');

        final TokenResponse? tokenResult = await _appAuth.token(
          TokenRequest(
            _clientId,
            _redirectUrl,
            authorizationCode: authResult.authorizationCode,
            codeVerifier: authResult.codeVerifier,
            serviceConfiguration: const AuthorizationServiceConfiguration(
              authorizationEndpoint: _authorizationEndpoint,
              tokenEndpoint: _tokenEndpoint,
            ),
            scopes: ['Files.ReadWrite.AppFolder', 'offline_access'],
          ),
        );

        if (tokenResult != null && tokenResult.accessToken != null) {
          print('[OAuth Diagnostic - OneDrive] Token exchange successful.');
          _accessToken = tokenResult.accessToken;
          await _secureStorage.write(key: 'onedrive_access_token', value: _accessToken);
        } else {
          throw Exception("Failed to get OneDrive access token during code exchange.");
        }
      }
    } catch (e) {
      throw Exception("OneDrive authentication failed: $e");
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    _accessToken = await _secureStorage.read(key: 'onedrive_access_token');
    return _accessToken != null;
  }

  @override
  Future<void> uploadBlob(String fileId, List<int> encryptedBytes, {void Function(double)? onProgress}) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/special/approot:/$fileId.enc:/content');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/octet-stream',
    };

    final request = http.Request('PUT', url)
      ..headers.addAll(headers)
      ..bodyBytes = encryptedBytes;

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('OneDrive upload failed: ${response.statusCode}');
    }
  }

  @override
  Future<List<int>> downloadBlob(String fileId, {void Function(double)? onProgress}) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/special/approot:/$fileId.enc:/content');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
    };

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200 || response.statusCode == 302) {
      // Sometimes Microsoft Graph returns 302 redirect for content
      return response.bodyBytes;
    } else {
      throw Exception('OneDrive download failed: ${response.statusCode}');
    }
  }

  @override
  Future<List<String>> listItems() async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/special/approot/children');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
    };

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final entries = data['value'] as List;
      return entries
          .map((e) => e['name'] as String)
          .where((name) => name.endsWith('.enc'))
          .toList();
    } else if (response.statusCode == 404) {
      // App root doesn't exist yet
      return [];
    } else {
      throw Exception('OneDrive list failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteItem(String fileId) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/special/approot:/$fileId.enc');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
    };

    final response = await http.delete(url, headers: headers);
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('OneDrive delete failed: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, int>> getQuota() async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/special/approot');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
    };

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final used = data['size'] ?? 0;
      
      return {
        'total': -1, // Indicates total capacity is unknown/hidden for privacy
        'used': used,
      };
    } else if (response.statusCode == 404) {
      // App folder hasn't been created yet
      return {
        'total': -1,
        'used': 0,
      };
    } else {
      throw Exception('OneDrive folder size failed: ${response.statusCode}');
    }
  }
}
