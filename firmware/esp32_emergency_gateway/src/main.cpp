#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <cstring>

#include "config.h"
#include "lora_transport.h"

static WebServer server(HTTP_PORT);
static String inbox[INBOX_CAP];
static int inboxCount = 0;
static int inboxHead = 0;

static void emergencyLog(const char *hop, const String &payload) {
  Serial.print("EMERGENCY [");
  Serial.print(hop);
  Serial.print("] ");
  Serial.println(payload);
}

static void addCors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

static void enqueueInbox(const String &packetJson) {
  inbox[inboxHead] = packetJson;
  inboxHead = (inboxHead + 1) % INBOX_CAP;
  if (inboxCount < INBOX_CAP) inboxCount++;
}

static String inboxJson() {
  JsonDocument doc;
  JsonArray packets = doc["packets"].to<JsonArray>();
  const int start = (inboxHead - inboxCount + INBOX_CAP) % INBOX_CAP;
  for (int i = 0; i < inboxCount; i++) {
    const String &raw = inbox[(start + i) % INBOX_CAP];
    JsonDocument pkt;
    if (deserializeJson(pkt, raw) == DeserializationError::Ok) {
      packets.add(pkt.as<JsonObject>());
    }
  }
  String out;
  serializeJson(doc, out);
  return out;
}

static void handleHealth() {
  addCors();
  LoRaSignalStatus signal = activeLoRaTransport().getSignalStatus();
  JsonDocument doc;
  doc["ok"] = true;
  doc["ssid"] = AP_SSID;
  doc["ip"] = WiFi.softAPIP().toString();
  doc["transport"] = EMERGENCY_TRANSPORT_MOCK ? "MOCK" : "LORA";
  doc["radio_linked"] = signal.linked;
  doc["radio_detail"] = signal.detail;
  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

static void handleEmergency() {
  addCors();
  if (server.method() == HTTP_OPTIONS) {
    server.send(204);
    return;
  }

  emergencyLog("http-rx", server.arg("plain"));
  JsonDocument body;
  DeserializationError err = deserializeJson(body, server.arg("plain"));
  if (err) {
    server.send(400, "application/json", "{\"ok\":false,\"error\":\"bad json\"}");
    return;
  }

  JsonObject pkt = body["pkt"].is<JsonObject>() ? body["pkt"].as<JsonObject>() : body.as<JsonObject>();
  String pktJson;
  serializeJson(pkt, pktJson);
  emergencyLog("encode", pktJson);

  const char *fwd = body["fwd"] | "wifi";
  bool wantLora = strcmp(fwd, "lora") == 0;
  LoRaTransport &radio = activeLoRaTransport();
  bool radioAck = false;

  if (wantLora) {
    emergencyLog("lora-tx", pktJson);
    radioAck = radio.send(reinterpret_cast<const uint8_t *>(pktJson.c_str()), pktJson.length());
    emergencyLog(radioAck ? "lora-ack-local" : "lora-fail", pktJson);
    if (!EMERGENCY_TRANSPORT_MOCK) {
      // Hardware path: do not claim RF success unless the driver returns true.
    }
  } else {
    emergencyLog("wifi-fwd", pktJson);
  }

  // Loopback inbox so two phones on this AP can demo without a second ESP32.
  enqueueInbox(pktJson);
  emergencyLog("inbox", pktJson);

  JsonDocument ack;
  ack["ack"] = true;
  ack["id"] = pkt["id"] | "";
  ack["seq"] = pkt["seq"] | 0;
  ack["fwd"] = fwd;
  ack["radio"] = radioAck;
  ack["mock"] = (bool)EMERGENCY_TRANSPORT_MOCK;
  String out;
  serializeJson(ack, out);
  server.send(200, "application/json", out);
}

static void handleInbox() {
  addCors();
  server.send(200, "application/json", inboxJson());
}

static void handleAck() {
  addCors();
  if (server.method() == HTTP_OPTIONS) {
    server.send(204);
    return;
  }
  emergencyLog("ack", server.arg("plain"));
  server.send(200, "application/json", "{\"ok\":true}");
}

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("EMERGENCY [boot] VitalReach ESP32 gateway stub");

  IPAddress ip(AP_LOCAL_IP);
  IPAddress gw(AP_GATEWAY);
  IPAddress mask(AP_SUBNET);
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(ip, gw, mask);
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.print("EMERGENCY [ap] SSID=");
  Serial.print(AP_SSID);
  Serial.print(" ip=");
  Serial.println(WiFi.softAPIP());

  activeLoRaTransport().initialize();

  server.on("/health", HTTP_GET, handleHealth);
  server.on("/emergency", HTTP_POST, handleEmergency);
  server.on("/emergency", HTTP_OPTIONS, handleEmergency);
  server.on("/inbox", HTTP_GET, handleInbox);
  server.on("/ack", HTTP_POST, handleAck);
  server.on("/ack", HTTP_OPTIONS, handleAck);
  server.begin();
  Serial.println("EMERGENCY [http] listening on :80");
}

void loop() {
  server.handleClient();

  // TODO(hardware): poll LoRaTransport::receive and enqueueInbox() when a
  // remote packet arrives on the doctor-side ESP32.
  uint8_t buf[256];
  int n = activeLoRaTransport().receive(buf, sizeof(buf), 0);
  if (n > 0) {
    String raw = String(reinterpret_cast<char *>(buf), n);
    emergencyLog("lora-rx", raw);
    enqueueInbox(raw);
  }
}
