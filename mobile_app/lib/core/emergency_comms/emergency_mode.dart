enum EmergencyMode {
  mock,
  localWifi,
  lora;

  String get wireName {
    switch (this) {
      case EmergencyMode.mock:
        return 'MOCK';
      case EmergencyMode.localWifi:
        return 'LOCAL_WIFI';
      case EmergencyMode.lora:
        return 'LORA';
    }
  }

  String get label {
    switch (this) {
      case EmergencyMode.mock:
        return 'Mock / simulation';
      case EmergencyMode.localWifi:
        return 'Local ESP32 Wi-Fi';
      case EmergencyMode.lora:
        return 'LoRa via ESP32';
    }
  }

  static EmergencyMode parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'LOCAL_WIFI':
      case 'WIFI':
      case 'LOCALWIFI':
        return EmergencyMode.localWifi;
      case 'LORA':
        return EmergencyMode.lora;
      default:
        return EmergencyMode.mock;
    }
  }
}
