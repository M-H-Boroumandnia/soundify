import 'package:safe_device/safe_device.dart';

class DeviceSecurityReport {
  final bool isRooted;
  final bool isEmulator;
  final bool isDevelopmentMode;
  final bool checkFailed;

  const DeviceSecurityReport({
    required this.isRooted,
    required this.isEmulator,
    required this.isDevelopmentMode,
    this.checkFailed = false,
  });

  bool get isSecure => !isRooted && !isEmulator && !checkFailed;
}

class DeviceSecurityService {
  DeviceSecurityReport? _cached;

  Future<DeviceSecurityReport> check({bool force = false}) async {
    if (_cached != null && !force) return _cached!;
    try {
      final results = await Future.wait([
        SafeDevice.isJailBroken,
        SafeDevice.isRealDevice,
        SafeDevice.isDevelopmentModeEnable,
      ]);
      return _cached = DeviceSecurityReport(
        isRooted: results[0],
        isEmulator: !results[1],
        isDevelopmentMode: results[2],
      );
    } catch (_) {
      return _cached = const DeviceSecurityReport(
        isRooted: false,
        isEmulator: false,
        isDevelopmentMode: false,
        checkFailed: true,
      );
    }
  }
}
