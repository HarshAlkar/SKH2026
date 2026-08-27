#include "lora_transport.h"
#include "config.h"

bool MockLoRaTransport::initialize() {
  ready_ = true;
  Serial.println("EMERGENCY [lora-mock] initialize — simulation only, no radio");
  return true;
}

bool MockLoRaTransport::send(const uint8_t *data, size_t len) {
  Serial.print("EMERGENCY [lora-mock] send ");
  Serial.print(len);
  Serial.println(" bytes (NOT transmitted over air)");
  delay(50);
  return true;  // local mock hop only
}

int MockLoRaTransport::receive(uint8_t *buffer, size_t maxLen, uint32_t timeoutMs) {
  delay(timeoutMs);
  (void)buffer;
  (void)maxLen;
  return 0;
}

bool MockLoRaTransport::isConnected() const { return ready_; }

LoRaSignalStatus MockLoRaTransport::getSignalStatus() const {
  LoRaSignalStatus status;
  status.linked = false;
  status.rssi = 0;
  status.snr = 0;
  status.detail = "Mock transport — radio not present";
  return status;
}

bool HardwareLoRaTransport::initialize() {
  // TODO(hardware): configure SPI pins (LORA_PIN_NSS/RST/DIO0) and begin()
  // the vendor driver for the module that arrives. Do not assume SX1278.
  Serial.println("EMERGENCY [lora-hw] initialize STUB — radio not wired");
  return false;
}

bool HardwareLoRaTransport::send(const uint8_t *data, size_t len) {
  (void)data;
  (void)len;
  Serial.println("EMERGENCY [lora-hw] send STUB — radio not connected");
  return false;
}

int HardwareLoRaTransport::receive(uint8_t *buffer, size_t maxLen, uint32_t timeoutMs) {
  (void)buffer;
  (void)maxLen;
  (void)timeoutMs;
  return 0;
}

bool HardwareLoRaTransport::isConnected() const { return false; }

LoRaSignalStatus HardwareLoRaTransport::getSignalStatus() const {
  LoRaSignalStatus status;
  status.linked = false;
  status.rssi = 0;
  status.snr = 0;
  status.detail = "Hardware transport stub — module not connected";
  return status;
}

static MockLoRaTransport mockTransport;
static HardwareLoRaTransport hardwareTransport;

LoRaTransport &activeLoRaTransport() {
#if EMERGENCY_TRANSPORT_MOCK
  return mockTransport;
#else
  return hardwareTransport;
#endif
}
