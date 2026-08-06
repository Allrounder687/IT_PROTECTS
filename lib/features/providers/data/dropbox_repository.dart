import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/storage_provider.dart';

class DropboxRepository implements StorageProvider {
  @override
  String get providerId => 'dropbox';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _clientId = 'l6vmq8c3oakywkz';
  static const String _clientSecret = 'rj3ckipd9w9pdup'; // Note: Typically PKCE does not require secret on mobile
  static const String _redirectUrl = 'com.syeds.itprotects://oauthredirect';
  static const String _authorizationEndpoint = 'https://www.dropbox.com/oauth2/authorize';
  static const String _tokenEndpoint = 'https://api.dropboxapi.com/oauth2/token';

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
          'token_access_type': 'offline', // Request refresh token for Dropbox
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
            'client_secret': _clientSecret,
            'redirect_uri': loopbackUrl,
          }
        );
        
        if (tokenResponse.statusCode == 200) {
          final data = jsonDecode(tokenResponse.body);
          _accessToken = data['access_token'];
          await _secureStorage.write(key: 'dropbox_access_token', value: _accessToken);
        } else {
          throw Exception("Failed to exchange code: ${tokenResponse.body}");
        }
      } else {
        final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            _clientId,
            _redirectUrl,
            serviceConfiguration: const AuthorizationServiceConfiguration(
              authorizationEndpoint: _authorizationEndpoint,
              tokenEndpoint: _tokenEndpoint,
            ),
            scopes: [], // Dropbox apps are usually scoped globally in console
          ),
        );

        if (result != null && result.accessToken != null) {
          _accessToken = result.accessToken;
          await _secureStorage.write(key: 'dropbox_access_token', value: _accessToken);
        } else {
          throw Exception("Failed to get Dropbox access token");
        }
      }
    } catch (e) {
      throw Exception("Dropbox authentication failed: $e");
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    _accessToken = await _secureStorage.read(key: 'dropbox_access_token');
    return _accessToken != null;
  }

  @override
  Future<void> uploadBlob(String fileId, List<int> encryptedBytes, {void Function(double)? onProgress}) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://content.dropboxapi.com/2/files/upload');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Dropbox-API-Arg': jsonEncode({
        'path': '/$fileId.enc',
        'mode': 'add',
        'autorename': true,
        'mute': false,
        'strict_conflict': false
      }),
      'Content-Type': 'application/octet-stream',
    };

    final request = http.Request('POST', url)
      ..headers.addAll(headers)
      ..bodyBytes = encryptedBytes;

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Dropbox upload failed: ${response.statusCode}');
    }
  }

  @override
  Future<List<int>> downloadBlob(String fileId, {void Function(double)? onProgress}) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://content.dropboxapi.com/2/files/download');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Dropbox-API-Arg': jsonEncode({'path': '/$fileId.enc'}),
    };

    final response = await http.post(url, headers: headers);
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Dropbox download failed: ${response.statusCode}');
    }
  }

  @override
  Future<List<String>> listItems() async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://api.dropboxapi.com/2/files/list_folder');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'path': '',
      'recursive': false,
      'include_media_info': false,
      'include_deleted': false,
      'include_has_explicit_shared_members': false
    });

    final response = await http.post(url, headers: headers, body: body);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final entries = data['entries'] as List;
      return entries
          .map((e) => e['name'] as String)
          .where((name) => name.endsWith('.enc'))
          .toList();
    } else {
      throw Exception('Dropbox list failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteItem(String fileId) async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://api.dropboxapi.com/2/files/delete_v2');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'path': '/$fileId.enc'});

    final response = await http.post(url, headers: headers, body: body);
    
    if (response.statusCode != 200) {
      throw Exception('Dropbox delete failed: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, int>> getQuota() async {
    if (_accessToken == null) throw Exception("Not authenticated");

    final url = Uri.parse('https://api.dropboxapi.com/2/users/get_space_usage');
    final headers = {
      'Authorization': 'Bearer $_accessToken',
    };

    final response = await http.post(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allocation = data['allocation'];
      
      int total = 0;
      if (allocation != null && allocation['.tag'] == 'individual') {
        total = allocation['allocated'] ?? 0;
      } else if (allocation != null && allocation['.tag'] == 'team') {
        total = allocation['allocated'] ?? 0;
      }

      int used = data['used'] ?? 0;

      return {
        'total': total,
        'used': used,
      };
    } else {
      throw Exception('Dropbox quota failed: ${response.statusCode}');
    }
  }
}
