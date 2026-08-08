import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class UpdaterState {
  final bool isLoading;
  final bool updateAvailable;
  final String? latestVersion;
  final String? error;

  UpdaterState({
    this.isLoading = false,
    this.updateAvailable = false,
    this.latestVersion,
    this.error,
  });

  UpdaterState copyWith({
    bool? isLoading,
    bool? updateAvailable,
    String? latestVersion,
    String? error,
  }) {
    return UpdaterState(
      isLoading: isLoading ?? this.isLoading,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      latestVersion: latestVersion ?? this.latestVersion,
      error: error ?? this.error,
    );
  }
}

class UpdaterNotifier extends StateNotifier<UpdaterState> {
  UpdaterNotifier() : super(UpdaterState());

  String? _apkDownloadUrl;
  String? _releaseUrl;

  Future<bool> checkForUpdates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/Allrounder687/IT_PROTECTS/releases/latest'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'] as String;
        _releaseUrl = data['html_url'] as String;

        // Parse assets
        final assets = data['assets'] as List;
        for (var asset in assets) {
          if (asset['name'] == 'app-release.apk') {
            _apkDownloadUrl = asset['browser_download_url'] as String;
          }
        }

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        // Simple string comparison (e.g., 'v1.0.23' vs '1.0.23')
        final sanitizedLatest = latestVersion.replaceAll('v', '');
        final sanitizedCurrent = currentVersion.replaceAll('v', '');

        if (sanitizedLatest != sanitizedCurrent && sanitizedLatest.isNotEmpty) {
          state = state.copyWith(
            isLoading: false,
            updateAvailable: true,
            latestVersion: latestVersion,
          );
          return true;
        }
      }
      state = state.copyWith(isLoading: false, updateAvailable: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> downloadAndInstallUpdate(BuildContext context) async {
    if (state.latestVersion == null || _releaseUrl == null) return;

    if (Platform.isAndroid && _apkDownloadUrl != null) {
      // Android: Download and install APK
      await _downloadApk(context, _apkDownloadUrl!);
    } else if (Platform.isIOS) {
      // iOS: Open release page / direct IPA link
      await _openUrl(_releaseUrl!);
    } else if (Platform.isWindows) {
      // Windows: Open release page and show toast
      await _openUrl(_releaseUrl!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update available on GitHub. Please restart app after installing.')),
        );
      }
    } else {
        await _openUrl(_releaseUrl!);
    }
  }

  Future<void> _downloadApk(BuildContext context, String url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Downloading Update...'),
          content: Padding(
            padding: EdgeInsets.all(16.0),
            child: LinearProgressIndicator(),
          ),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/app-update.apk';

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          // Could update progress here if we passed a ValueNotifier
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog
      }

      await OpenFilex.open(savePath);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download update: $e')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final updaterProvider = StateNotifierProvider<UpdaterNotifier, UpdaterState>((ref) {
  return UpdaterNotifier();
});
