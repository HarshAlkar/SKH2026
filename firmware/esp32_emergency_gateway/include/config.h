#ifndef VR_CONFIG_H
#define VR_CONFIG_H

#define AP_SSID "VitalReach-EMG"
#define AP_PASS "vitalreach"

#define AP_LOCAL_IP 192, 168, 4, 1
#define AP_GATEWAY 192, 168, 4, 1
#define AP_SUBNET 255, 255, 255, 0

#define HTTP_PORT 80
#define INBOX_CAP 16

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
