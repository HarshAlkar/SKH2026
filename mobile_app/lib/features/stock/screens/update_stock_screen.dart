import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medicine_stock_model.dart';

String _newClientId() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String h(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

List<dynamic> _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

class _NamedId {
  final int id;
  final String name;
  const _NamedId(this.id, this.name);
}

class UpdateStockScreen extends StatefulWidget {
  final MedicineStockModel? batch;

  const UpdateStockScreen({super.key, this.batch});

  @override
  State<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends State<UpdateStockScreen> {
  List<MedicineStockModel> _batches = [];
  List<_NamedId> _catalog = [];
  List<_NamedId> _facilities = [];
  int? _batchId;
  int? _catalogId;
  int? _facilityId;
  String _mode = 'existing';
  String _action = 'add';
  final _qty = TextEditingController(text: '10');
  final _reason = TextEditingController(text: 'New Delivery Received');
  final _supplier = TextEditingController();
  final _invoice = TextEditingController();
  final _notes = TextEditingController();
  final _batchNo = TextEditingController();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _batchId = widget.batch?.id;
    _batchNo.text =
        'ASHA-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}'
        '${DateTime.now().day.toString().padLeft(2, '0')}';
    _load();
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    _supplier.dispose();
    _invoice.dispose();
    _notes.dispose();
    _batchNo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? loadError;
    try {
      final results = await Future.wait([
        OfflineApi.instance.get('/stock/batches/'),
        OfflineApi.instance.get('/stock/catalog/?active=1'),
        OfflineApi.instance.get('/stock/facilities/'),
      ]);

      final batches = _asList(results[0])
          .whereType<Map>()
          .map((e) => MedicineStockModel.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.id > 0)
          .toList();
      final catalog = _asList(results[1]).whereType<Map>().map((e) {
        final id = int.tryParse('${e['id']}') ?? 0;
        final name = '${e['display_name'] ?? e['name'] ?? ''}'.trim();
        final sku = '${e['sku'] ?? ''}'.trim();
        return _NamedId(id, sku.isEmpty ? name : '$name ($sku)');
      }).where((c) => c.id > 0 && c.name.isNotEmpty).toList();
      final facilities = _asList(results[2]).whereType<Map>().map((e) {
        final id = int.tryParse('${e['id']}') ?? 0;
        final name = '${e['name'] ?? ''}'.trim();
        final village = '${e['village'] ?? ''}'.trim();
        final label = village.isEmpty ? name : '$name · $village';
        return _NamedId(id, label);
      }).where((f) => f.id > 0).toList();

      setState(() {
        _batches = batches;
        _catalog = catalog;
        _facilities = facilities;
        if (_batchId == null || !batches.any((b) => b.id == _batchId)) {
          _batchId = batches.isNotEmpty ? batches.first.id : null;
        }
        _facilityId ??= widget.batch?.facilityId ??
            (facilities.isNotEmpty ? facilities.first.id : null);
        _catalogId ??= catalog.isNotEmpty ? catalog.first.id : null;
        if (batches.isEmpty && widget.batch == null) {
          _mode = 'new';
        }
      });
    } catch (e) {
      loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = loadError;
        });
      }
    }
  }

  MedicineStockModel? get _selected {
    try {
      return _batches.firstWhere((b) => b.id == _batchId);
    } catch (_) {
      return widget.batch;
    }
  }

  InputDecoration _field(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
    );
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qty.text.trim()) ?? -1;
    if (qty < 0) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }

    Map<String, dynamic> body;
    if (_mode == 'new') {
      if (_facilityId == null) {
        setState(() => _error = 'Select a facility');
        return;
      }
      if (_catalogId == null) {
        setState(() => _error = 'Select a medicine from the catalog');
        return;
      }
      final batchNo = _batchNo.text.trim();
      if (batchNo.isEmpty) {
        setState(() => _error = 'Enter a batch number');
        return;
      }
      body = {
        'facility_id': _facilityId,
        'catalog_id': _catalogId,
        'batch_no': batchNo,
        'expiry_date':
            '${_expiry.year.toString().padLeft(4, '0')}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',
        'action': _action,
        'quantity': qty,
        'client_id': _newClientId(),
        'reason': _reason.text.trim(),
        'supplier_name': _supplier.text.trim(),
        'invoice_no': _invoice.text.trim(),
        'notes': _notes.text.trim(),
      };
    } else {
      if (_batchId == null) {
        setState(() {
          _error = _batches.isEmpty
              ? 'No existing stock yet. Use “New medicine / batch” to add the first delivery.'
              : 'Select a medicine batch';
        });
        return;
      }
      body = {
        'batch_id': _batchId,
        'action': _action,
        'quantity': qty,
        'client_id': _newClientId(),
        'reason': _reason.text.trim(),
        'supplier_name': _supplier.text.trim(),
        'invoice_no': _invoice.text.trim(),
        'notes': _notes.text.trim(),
      };
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await OfflineApi.instance.post(
        '/stock/adjust/',
        body: body,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 8)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Widget _modeChip(String id, String label) {
    final selected = _mode == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _mode = id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final current = selected?.quantity ?? 0;
    final qty = int.tryParse(_qty.text) ?? 0;
    int next = current;
    if (_action == 'add') {
      next = current + qty;
    } else if (_action == 'adjust') {
      next = qty;
    } else {
      next = (current - qty).clamp(0, 1 << 30);
    }
    final validBatchId =
        _batches.any((b) => b.id == _batchId) ? _batchId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Update Stock'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    _modeChip('existing', 'Existing batch'),
                    _modeChip('new', 'New medicine / batch'),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '1. Select Medicine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_mode == 'existing') ...[
                  if (_batches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No stock batches at your PHC yet. Switch to “New medicine / batch” to record a delivery.',
                      ),
                    ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('batch-$validBatchId-${_batches.length}'),
                    isExpanded: true,
                    initialValue: validBatchId,
                    hint: const Text('Select medicine / batch'),
                    items: _batches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              '${b.medicineName} · ${b.batchNo} (${b.quantity})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _batches.isEmpty
                        ? null
                        : (v) => setState(() => _batchId = v),
                    decoration: _field('Medicine / Batch'),
                  ),
                ] else ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey('facility-$_facilityId-${_facilities.length}'),
                    isExpanded: true,
                    initialValue: _facilities.any((f) => f.id == _facilityId)
                        ? _facilityId
                        : null,
                    hint: const Text('Select facility'),
                    items: _facilities
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _facilityId = v),
                    decoration: _field('Facility'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('catalog-$_catalogId-${_catalog.length}'),
                    isExpanded: true,
                    initialValue: _catalog.any((c) => c.id == _catalogId)
                        ? _catalogId
                        : null,
                    hint: const Text('Select catalog medicine'),
                    items: _catalog
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _catalogId = v),
                    decoration: _field('Medicine'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _batchNo,
                    decoration: _field('Batch Number'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickExpiry,
                    child: InputDecorator(
                      decoration: _field('Expiry Date'),
                      child: Text(
                        '${_expiry.year.toString().padLeft(4, '0')}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '2. Stock Adjustment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('action-$_action'),
                  isExpanded: true,
                  initialValue: _action,
                  items: const [
                    DropdownMenuItem(value: 'add', child: Text('Add Stock (+)')),
                    DropdownMenuItem(value: 'remove', child: Text('Remove Stock (−)')),
                    DropdownMenuItem(value: 'adjust', child: Text('Set Absolute Qty')),
                    DropdownMenuItem(value: 'disposal', child: Text('Disposal')),
                    DropdownMenuItem(value: 'return', child: Text('Return to Supplier')),
                  ],
                  onChanged: (v) => setState(() => _action = v ?? 'add'),
                  decoration: _field('Action'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _field('Quantity'),
                ),
                if (_mode == 'existing' && selected != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Current ($current)  →  New ($next)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '3. Traceability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reason,
                  decoration: _field('Reason'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _supplier,
                  decoration: _field('Supplier / Source'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invoice,
                  decoration: _field('Invoice / PO'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: _field('Notes'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Update Stock'),
                ),
              ],
            ),
    );
  }
}
