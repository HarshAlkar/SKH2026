#ifndef VR_CONFIG_H
#define VR_CONFIG_H

// SoftAP credentials — MUST be changed before any field deployment.
// Do not ship shared default passwords in production firmware builds.
#ifndef AP_SSID
#define AP_SSID "VitalReach-EMG"
#endif
#ifndef AP_PASS
#define AP_PASS "CHANGE_ME_BEFORE_DEPLOY"
#endif

#define AP_LOCAL_IP 192, 168, 4, 1
#define AP_GATEWAY 192, 168, 4, 1
#define AP_SUBNET 255, 255, 255, 0

#define HTTP_PORT 80
#define INBOX_CAP 16

// Device identity for future authenticated LoRa / gateway ingest
#ifndef DEVICE_ID
#define DEVICE_ID "UNPROVISIONED"
#endif

// TODO(hardware): set to 0 and implement LoRaTransport::send/receive
// against the actual module (SX127x / SX126x / etc.) when it arrives.
#ifndef EMERGENCY_TRANSPORT_MOCK
#define EMERGENCY_TRANSPORT_MOCK 1
#endif

// Placeholder pin map — do not assume a specific LoRa board.
#define LORA_PIN_NSS -1
#define LORA_PIN_RST -1
#define LORA_PIN_DIO0 -1

#endif
