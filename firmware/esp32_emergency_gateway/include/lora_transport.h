#ifndef VR_LORA_TRANSPORT_H
#define VR_LORA_TRANSPORT_H

#include <Arduino.h>

struct LoRaSignalStatus {
  bool linked;
  int rssi;
  float snr;
  const char *detail;
};

class LoRaTransport {
public:
  virtual ~LoRaTransport() {}
  virtual bool initialize() = 0;
  virtual bool send(const uint8_t *data, size_t len) = 0;
  virtual int receive(uint8_t *buffer, size_t maxLen, uint32_t timeoutMs) = 0;
  virtual bool isConnected() const = 0;
  virtual LoRaSignalStatus getSignalStatus() const = 0;
};

class MockLoRaTransport : public LoRaTransport {
public:
  bool initialize() override;
  bool send(const uint8_t *data, size_t len) override;
  int receive(uint8_t *buffer, size_t maxLen, uint32_t timeoutMs) override;
  bool isConnected() const override;
  LoRaSignalStatus getSignalStatus() const override;

private:
  bool ready_ = false;
};

// TODO(hardware): implement HardwareLoRaTransport for the chosen module.
// Keep the same methods so main.cpp does not change beyond the factory.

class HardwareLoRaTransport : public LoRaTransport {
public:
  bool initialize() override;
  bool send(const uint8_t *data, size_t len) override;
  int receive(uint8_t *buffer, size_t maxLen, uint32_t timeoutMs) override;
  bool isConnected() const override;
  LoRaSignalStatus getSignalStatus() const override;
};

LoRaTransport &activeLoRaTransport();

#endif
