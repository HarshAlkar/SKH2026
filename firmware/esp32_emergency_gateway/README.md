# VitalReach ESP32 emergency gateway (stub)

This folder is a **compile-ready architecture stub**. A LoRa radio is **not** connected. Do not treat serial logs of `lora-mock` as over-the-air success.

## Role

Patient phone and doctor/ASHA phone talk HTTP to this ESP32 over a local SoftAP. The ESP32 owns the future LoRa radio.

```
Patient app  --HTTP-->  ESP32 SoftAP  --LoRaTransport-->  (radio later)
Doctor app   --HTTP GET /inbox--  ESP32 SoftAP
```

Until a second ESP32 + radio exists, this firmware **loops** received `/emergency` packets into `/inbox` so two phones on the same AP can demo the app path.

## Access point

| Setting | Value |
|---|---|
| SSID | `VitalReach-EMG` |
| Password | `vitalreach` |
| IP | `192.168.4.1` |
| HTTP | port 80 |

Join the AP from the phone, then set **ESP32 gateway** in VitalReach Settings to `192.168.4.1` and mode to `LOCAL_WIFI` or `LORA`.

## HTTP API

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | AP + transport status |
| POST | `/emergency` | Body `{ "fwd": "wifi"\|"lora", "pkt": { compact packet } }` |
| GET | `/inbox` | `{ "packets": [ ... ] }` |
| POST | `/ack` | Compact ACK from doctor/ASHA |

Compact packet keys match the Flutter encoder: `v,id,seq,eid,pid,ts,typ,pri,lat,lng,n,age,vil,ph,ttl`.

## Transport switch

Default is **MOCK** (`EMERGENCY_TRANSPORT_MOCK=1` in `platformio.ini`).

When the module arrives:

1. Fill pin placeholders in `include/config.h` (`LORA_PIN_NSS`, `LORA_PIN_RST`, `LORA_PIN_DIO0`).
2. Implement `HardwareLoRaTransport` in `src/lora_transport.cpp` for the actual chip. Do not assume SX1278 vs SX1262 until the board is known.
3. Set `-DEMERGENCY_TRANSPORT_MOCK=0` in `platformio.ini`.
4. Doctor-side unit should call `receive()` and `enqueueInbox()` (hook already in `loop()`).

## Build

```
pio run
```

Flash only when hardware is on the desk:

```
pio run -t upload
pio device monitor
```

Serial hops look like: `EMERGENCY [http-rx]`, `[encode]`, `[lora-tx]` or `[wifi-fwd]`, `[inbox]`.
