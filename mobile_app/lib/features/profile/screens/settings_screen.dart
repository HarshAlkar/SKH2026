import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/emergency_comms/emergency_comms.dart';
import '../../../core/emergency_comms/emergency_comms_config.dart';
import '../../../core/emergency_comms/emergency_mode.dart';
import '../../../core/recovery/disaster_recovery_service.dart';
import '../../../core/recovery/recovery_status_banner.dart';
import '../../../core/services/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../widgets/profile_avatar.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _gatewayController;
  bool _savingHost = false;
  bool _savingGateway = false;
  bool _simulating = false;
  bool _simulatingBlackout = false;
  late bool _calls;
  late bool _chat;
  late bool _medicine;
  late String _language;
  late EmergencyMode _emergencyMode;

  final _store = SettingsStore.instance;
  String t(String en, String hi) => _store.t(en, hi);

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: AppConfig.host);
    _gatewayController = TextEditingController(text: EmergencyCommsConfig.gatewayHost);
    _calls = _store.callsEnabled;
    _chat = _store.chatEnabled;
    _medicine = _store.medicineEnabled;
    _language = _store.language;
    _emergencyMode = EmergencyCommsConfig.mode;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  Future<void> _saveHost() async {
    final value = _hostController.text.trim();
    if (value.isEmpty) return;
    setState(() => _savingHost = true);
    await AppConfig.setHost(value);
    if (!mounted) return;
    setState(() => _savingHost = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${t('Server host saved', 'सर्वर होस्ट सेव हुआ')}: $value')),
    );
  }

  Future<void> _saveGateway() async {
    final value = _gatewayController.text.trim();
    if (value.isEmpty) return;
    setState(() => _savingGateway = true);
    await EmergencyComms.instance.setGatewayHost(value);
    if (!mounted) return;
    setState(() => _savingGateway = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${t('ESP32 gateway saved', 'ESP32 गेटवे सेव हुआ')}: $value')),
    );
  }

  Future<void> _changeMode(EmergencyMode? mode) async {
    if (mode == null) return;
    await EmergencyComms.instance.setMode(mode);
    if (!mounted) return;
    setState(() => _emergencyMode = mode);
  }

  Future<void> _simulateIncoming() async {
    setState(() => _simulating = true);
    try {
      await EmergencyComms.instance.injectSimulatedIncoming();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Simulated emergency packet injected', 'सिम्युलेटेड इमरजेंसी पैकेट भेजा गया'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('Could not simulate packet', 'पैकेट सिम्युलेट नहीं हो सका')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Future<void> _simulateBlackout() async {
    setState(() => _simulatingBlackout = true);
    try {
      final res = await DisasterRecoveryService.instance.simulateBlackoutFaultInjection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.success
                ? t('✅ Blackout Recovery Succeeded: ${res.recordsRestored} records restored, ${res.operationsReplayed} pending ops replayed.',
                    '✅ ब्लैकआउट रिकवरी सफल: ${res.recordsRestored} रिकॉर्ड्स और ${res.operationsReplayed} इन-फ़्लाइट ऑपरेशन्स रीस्टोर हुए।')
                : t('❌ Recovery Failed: ${res.statusMessage}', '❌ रिकवरी विफल: ${res.statusMessage}'),
          ),
          backgroundColor: res.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulation error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _simulatingBlackout = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('Change password', 'पासवर्ड बदलें')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: InputDecoration(labelText: t('Current password', 'वर्तमान पासवर्ड')),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: InputDecoration(labelText: t('New password', 'नया पासवर्ड')),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(labelText: t('Confirm new password', 'नया पासवर्ड दोहराएँ')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('Cancel', 'रद्द'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('Update', 'अपडेट'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (next.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Password must be at least 6 characters', 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए'))),
      );
      return;
    }
    if (next.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('New passwords do not match', 'नए पासवर्ड मेल नहीं खाते'))),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(current.text, next.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? t('Password updated', 'पासवर्ड अपडेट हो गया')
              : (auth.error ?? t('Could not change password', 'पासवर्ड नहीं बदला जा सका')),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          t('Settings', 'सेटिंग्स'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InkWell(
            onTap: () {
              if (widget.embedded) {
                Navigator.pushNamed(context, AppRoutes.profile);
              } else {
                Navigator.pushNamed(context, AppRoutes.profile);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    user: user,
                    radius: 28,
                    backgroundColor: AppColors.lightBlue,
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : t('Your profile', 'आपकी प्रोफ़ाइल'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          user?.phoneNumber ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const RecoveryStatusBanner(),
          const SizedBox(height: 16),
          _label(t('ACCOUNT', 'खाता')),
          _card([
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(t('Change password', 'पासवर्ड बदलें')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ]),
          const SizedBox(height: 20),
          _label(t('NOTIFICATIONS', 'सूचनाएँ')),
          _card([
            SwitchListTile(
              secondary: const Icon(Icons.call_outlined),
              title: Text(t('Incoming calls', 'आने वाली कॉल')),
              value: _calls,
              onChanged: (v) async {
                await _store.setCallsEnabled(v);
                setState(() => _calls = v);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.chat_outlined),
              title: Text(t('Messages', 'संदेश')),
              value: _chat,
              onChanged: (v) async {
                await _store.setChatEnabled(v);
                setState(() => _chat = v);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.medication_outlined),
              title: Text(t('Medicine reminders', 'दवाई रिमाइंडर')),
              value: _medicine,
              onChanged: (v) async {
                await _store.setMedicineEnabled(v);
                setState(() => _medicine = v);
              },
            ),
          ]),
          const SizedBox(height: 20),
          _label(t('LANGUAGE', 'भाषा')),
          _card([
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (v) async {
                if (v == null) return;
                await _store.setLanguage(v);
                setState(() => _language = v);
              },
            ),
            RadioListTile<String>(
              title: const Text('हिन्दी'),
              value: 'hi',
              groupValue: _language,
              onChanged: (v) async {
                if (v == null) return;
                await _store.setLanguage(v);
                setState(() => _language = v);
              },
            ),
          ]),
          const SizedBox(height: 20),
          _label(t('SERVER', 'सर्वर')),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: t('API host', 'एपीआई होस्ट'),
                  hintText: '10.0.2.2 or http://192.168.1.10:8000',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ElevatedButton(
                onPressed: _savingHost ? null : _saveHost,
                child: Text(_savingHost ? t('Saving...', 'सेव हो रहा है...') : t('Save host', 'होस्ट सेव करें')),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _label(t('OFFLINE EMERGENCY', 'ऑफ़लाइन इमरजेंसी')),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                EmergencyComms.instance.statusLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            RadioListTile<EmergencyMode>(
              title: Text(t('Mock / simulation', 'मॉक / सिमुलेशन')),
              subtitle: Text(t('No radio. Logs packet hops.', 'रेडियो नहीं. पैकेट लॉग होता है.')),
              value: EmergencyMode.mock,
              groupValue: _emergencyMode,
              onChanged: _changeMode,
            ),
            RadioListTile<EmergencyMode>(
              title: Text(t('Local ESP32 Wi-Fi', 'लोकल ESP32 वाई-फाई')),
              subtitle: Text(t('HTTP to gateway AP. Radio optional.', 'गेटवे AP पर HTTP. रेडियो वैकल्पिक.')),
              value: EmergencyMode.localWifi,
              groupValue: _emergencyMode,
              onChanged: _changeMode,
            ),
            RadioListTile<EmergencyMode>(
              title: Text(t('LoRa via ESP32', 'ESP32 से LoRa')),
              subtitle: Text(t('Same HTTP; firmware TX on radio when wired.', 'वही HTTP; रेडियो जुड़ने पर फर्मवेयर भेजेगा.')),
              value: EmergencyMode.lora,
              groupValue: _emergencyMode,
              onChanged: _changeMode,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _gatewayController,
                decoration: InputDecoration(
                  labelText: t('ESP32 gateway', 'ESP32 गेटवे'),
                  hintText: EmergencyCommsConfig.defaultGatewayHost,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ElevatedButton(
                onPressed: _savingGateway ? null : _saveGateway,
                child: Text(_savingGateway ? t('Saving...', 'सेव हो रहा है...') : t('Save gateway', 'गेटवे सेव करें')),
              ),
            ),
            if (user?.role == 'doctor' || user?.role == 'asha_worker')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: _simulating ? null : _simulateIncoming,
                  icon: const Icon(Icons.cell_tower),
                  label: Text(
                    _simulating
                        ? t('Injecting...', 'भेजा जा रहा है...')
                        : t('Simulate incoming LoRa packet', 'आने वाला LoRa पैकेट सिम्युलेट करें'),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          _label(t('BLACKOUT RESILIENCE (HACKATHON DEMO)', 'ब्लैकआउट रेजिलिएंस (डेमो)')),
          _card([
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.primary),
              title: Text(t('Primary Store Resilience', 'प्राइमरी स्टोर रेजिलिएंस')),
              subtitle: Text(t('AES-256 Snapshots + In-flight Replay Engine', 'AES-256 स्नैपशॉट + इन-फ़्लाइट रिप्ले इंजन')),
              trailing: ValueListenableBuilder<RecoveryState>(
                valueListenable: DisasterRecoveryService.instance.stateNotifier,
                builder: (context, state, _) {
                  final isNormal = state == RecoveryState.normal;
                  return Chip(
                    label: Text(
                      isNormal ? 'HEALTHY' : state.name.toUpperCase(),
                      style: TextStyle(
                        color: isNormal ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: isNormal ? Colors.green.shade50 : Colors.orange.shade50,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _simulatingBlackout ? null : _simulateBlackout,
                  icon: _simulatingBlackout
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.flash_on),
                  label: Text(
                    _simulatingBlackout
                        ? t('Simulating Blackout & Recovering...', 'ब्लैकआउट सिम्युलेट और रिकवर हो रहा है...')
                        : t('Simulate Blackout / Corrupt Primary Store', 'ब्लैकआउट सिम्युलेट करें (प्राइमरी स्टोर करप्ट)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _label(t('ABOUT', 'जानकारी')),
          _card([
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t('App version', 'ऐप संस्करण')),
              trailing: const Text('1.0.0'),
            ),
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: Text(t('Logout', 'लॉग आउट')),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}
