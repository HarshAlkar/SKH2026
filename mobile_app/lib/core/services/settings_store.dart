import 'storage_service.dart';

class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _callsKey = 'notif_calls';
  static const _chatKey = 'notif_chat';
  static const _medicineKey = 'notif_medicine';
  static const _languageKey = 'app_language';
  static const _emergencyModeKey = 'emergency_mode';
  static const _emergencyGatewayKey = 'emergency_gateway_host';

  bool get callsEnabled => StorageService.getBoolSync(_callsKey, defaultValue: true);
  bool get chatEnabled => StorageService.getBoolSync(_chatKey, defaultValue: true);
  bool get medicineEnabled => StorageService.getBoolSync(_medicineKey, defaultValue: true);
  String get language => StorageService.getStringSync(_languageKey) ?? 'en';
  bool get isHindi => language == 'hi';
  bool get isMarathi => language == 'mr';
  String? get emergencyMode => StorageService.getStringSync(_emergencyModeKey);
  String? get emergencyGatewayHost => StorageService.getStringSync(_emergencyGatewayKey);

  Future<void> setCallsEnabled(bool value) => StorageService.saveBoolSync(_callsKey, value);
  Future<void> setChatEnabled(bool value) => StorageService.saveBoolSync(_chatKey, value);
  Future<void> setMedicineEnabled(bool value) => StorageService.saveBoolSync(_medicineKey, value);
  Future<void> setLanguage(String value) => StorageService.saveStringSync(_languageKey, value);
  Future<void> setEmergencyMode(String value) => StorageService.saveStringSync(_emergencyModeKey, value);
  Future<void> setEmergencyGatewayHost(String value) =>
      StorageService.saveStringSync(_emergencyGatewayKey, value);

  String t(String en, String hi, [String? mr]) {
    if (isMarathi && mr != null) return mr;
    return isHindi ? hi : en;
  }
}
