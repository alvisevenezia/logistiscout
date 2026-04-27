import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:carrier_info/carrier_info.dart';

import 'package:logistiscout/services/local_storage_service.dart';

import 'dart:developer' as developer;

class ClientContextService {
  ClientContextService._();

  static final ClientContextService instance = ClientContextService._();

  final LocalStorageService _localStorage = LocalStorageService.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Future<_ClientContextSnapshot>? _cachedSnapshot;

  Future<Map<String, String>> buildHeaders() async {
    final snapshot = await _loadSnapshot();
    return snapshot.toHeaders();
  }

  Future<_ClientContextSnapshot> _loadSnapshot() {
    return _cachedSnapshot ??= _collectSnapshot();
  }

  Future<_ClientContextSnapshot> _collectSnapshot() async {
    final installationId = await _localStorage.getOrCreateInstallationId();
    final packageInfo = await PackageInfo.fromPlatform();
    final connectivityType = await _resolveConnectivityType();
    final platformInfo = await _resolvePlatformInfo();

    return _ClientContextSnapshot(
      installationId: installationId,
      appVersion: packageInfo.version.isEmpty
          ? null
          : '${packageInfo.version}+${packageInfo.buildNumber}',
      platform: platformInfo.platform,
      osVersion: platformInfo.osVersion,
      deviceModel: platformInfo.deviceModel,
      networkType: connectivityType,
      networkGeneration: platformInfo.networkGeneration,
    );
  }

  Future<String?> _resolveConnectivityType() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final normalized = _firstConnectivityResult(results);
      return normalized?.name;
    } catch (_) {
      return null;
    }
  }

  ConnectivityResult? _firstConnectivityResult(Object? value) {
    if (value is ConnectivityResult) {
      return value;
    }
    if (value is Iterable<ConnectivityResult>) {
      return value.isEmpty ? null : value.first;
    }
    return null;
  }

  Future<String?> _resolveAndroidNetworkGeneration() async {
    try {
      final carrierInfo = await CarrierInfo.getAndroidInfo();
      final telephonyInfo = carrierInfo?.telephonyInfo;

      developer.log('Android telephony info: $telephonyInfo');

      if (telephonyInfo == null || telephonyInfo.isEmpty) {
        return null;
      }

      return telephonyInfo[0].networkGeneration;
    } catch (e) {
      developer.log('Failed to get Android network generation: $e');
      return null;
    }
  }

  Future<String?> _resolveIosNetworkGeneration() async {
    try {
      final carrierInfo = await CarrierInfo.getIosInfo();

      for (final radioType
          in carrierInfo.carrierRadioAccessTechnologyTypeList) {
        final generation = _mapRadioTypeToGeneration(radioType);
        if (generation != null) {
          return generation;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String? _mapRadioTypeToGeneration(String? radioType) {
    if (radioType == null) {
      return null;
    }

    final value = radioType.trim().toUpperCase();
    if (value.isEmpty) {
      return null;
    }
    if (value.contains('NR')) {
      return '5G';
    }
    if (value == 'LTE' || value == 'LTEA' || value.contains('EUTRAN')) {
      return '4G';
    }
    if (value.contains('WCDMA') ||
        value.contains('HSDPA') ||
        value.contains('HSUPA') ||
        value.contains('HSPA') ||
        value.contains('CDMAEVDO') ||
        value.contains('UMTS') ||
        value.contains('TD_SCDMA') ||
        value.contains('3G')) {
      return '3G';
    }
    if (value.contains('GPRS') ||
        value.contains('EDGE') ||
        value.contains('GSM') ||
        value.contains('CDMA1X') ||
        value.contains('IDEN') ||
        value.contains('2G')) {
      return '2G';
    }

    return null;
  }

  Future<_PlatformInfo> _resolvePlatformInfo() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return _PlatformInfo(
        platform: 'web',
        osVersion: webInfo.userAgent,
        deviceModel: webInfo.appName,
        networkGeneration: null,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await _deviceInfo.androidInfo;
        final networkGeneration = await _resolveAndroidNetworkGeneration();
        return _PlatformInfo(
          platform: 'android',
          osVersion: 'Android ${androidInfo.version.release}',
          deviceModel: '${androidInfo.manufacturer} ${androidInfo.model}'
              .trim(),
          networkGeneration: networkGeneration,
        );
      case TargetPlatform.iOS:
        final iosInfo = await _deviceInfo.iosInfo;
        final networkGeneration = await _resolveIosNetworkGeneration();
        return _PlatformInfo(
          platform: 'ios',
          osVersion: 'iOS ${iosInfo.systemVersion}',
          deviceModel: iosInfo.utsname.machine,
          networkGeneration: networkGeneration,
        );
      case TargetPlatform.macOS:
        final macInfo = await _deviceInfo.macOsInfo;
        return _PlatformInfo(
          platform: 'macos',
          osVersion: macInfo.osRelease,
          deviceModel: macInfo.model,
          networkGeneration: null,
        );
      case TargetPlatform.windows:
        final windowsInfo = await _deviceInfo.windowsInfo;
        return _PlatformInfo(
          platform: 'windows',
          osVersion: windowsInfo.buildNumber.toString(),
          deviceModel: windowsInfo.computerName,
          networkGeneration: null,
        );
      case TargetPlatform.linux:
        final linuxInfo = await _deviceInfo.linuxInfo;
        return _PlatformInfo(
          platform: 'linux',
          osVersion: linuxInfo.prettyName,
          deviceModel: linuxInfo.name,
          networkGeneration: null,
        );
      case TargetPlatform.fuchsia:
        return const _PlatformInfo(
          platform: 'fuchsia',
          osVersion: 'unknown',
          deviceModel: 'unknown',
          networkGeneration: null,
        );
    }
  }
}

class _ClientContextSnapshot {
  const _ClientContextSnapshot({
    required this.installationId,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.networkType,
    required this.networkGeneration,
  });

  final String installationId;
  final String? appVersion;
  final String platform;
  final String? osVersion;
  final String? deviceModel;
  final String? networkType;
  final String? networkGeneration;

  Map<String, String> toHeaders() {
    final headers = <String, String>{
      'X-Client-Installation-Id': installationId,
      'X-Installation-Id': installationId,
      'X-Client-Platform': platform,
    };

    if (appVersion != null && appVersion!.isNotEmpty) {
      headers['X-Client-App-Version'] = appVersion!;
    }
    if (osVersion != null && osVersion!.isNotEmpty) {
      headers['X-Client-OS-Version'] = osVersion!;
    }
    if (deviceModel != null && deviceModel!.isNotEmpty) {
      headers['X-Client-Device-Model'] = deviceModel!;
    }
    if (networkType != null && networkType!.isNotEmpty) {
      headers['X-Client-Network-Type'] = networkType!;
    }
    if (networkGeneration != null && networkGeneration!.isNotEmpty) {
      headers['X-Client-Network-Generation'] = networkGeneration!;
    }

    return headers;
  }
}

class _PlatformInfo {
  const _PlatformInfo({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.networkGeneration,
  });

  final String platform;
  final String? osVersion;
  final String? deviceModel;
  final String? networkGeneration;
}
