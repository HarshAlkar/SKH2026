import 'package:flutter/material.dart';

import '../../../core/sync/offline_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medicine_stock_model.dart';

String _newClientId() {
  // RFC4122-ish UUID v4 without depending on a package.
  final rand = DateTime.now().microsecondsSinceEpoch;
  String hex(int n, int width) => n.toRadixString(16).padLeft(width, '0');
  final a = hex(rand & 0xffffffff, 8);
  final b = hex((rand >> 8) & 0xffff, 4);
  final c = '4${hex((rand >> 16) & 0xfff, 3)}';
  final d = hex(0x8000 | ((rand >> 20) & 0x3fff), 4);
  final e = hex((rand * 31) & 0xffffffffffff, 12);
  return '$a-$b-$c-$d-$e';
}

class UpdateStockScreen extends StatefulWidget {
  final MedicineStockModel? batch;

  const UpdateStockScreen({super.key, this.batch});

  @override
  State<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends State<UpdateStockScreen> {
  List<MedicineStockModel> _batches = [];
  int? _batchId;
  String _action = 'add';
  final _qty = TextEditingController(text: '10');
  final _reason = TextEditingController(text: 'New Delivery Received');
  final _supplier = TextEditingController();
  final _invoice = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _batchId = widget.batch?.id;
    _loadBatches();
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    _supplier.dispose();
    _invoice.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    try {
      final data = await OfflineApi.instance.get('/stock/batches/');
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
              ? data['results'] as List
              : <dynamic>[];
      setState(() {
        _batches = list
            .whereType<Map>()
            .map((e) => MedicineStockModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _batchId ??= _batches.isNotEmpty ? _batches.first.id : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  MedicineStockModel? get _selected {
    try {
      return _batches.firstWhere((b) => b.id == _batchId);
    } catch (_) {
      return widget.batch;
    }
  }

  Future<void> _submit() async {
    if (_batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a batch')),
      );
      return;
    }
    final qty = int.tryParse(_qty.text.trim()) ?? -1;
    if (qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await OfflineApi.instance.post(
        '/stock/adjust/',
        body: {
          'batch_id': _batchId,
          'action': _action,
          'quantity': qty,
          'client_id': _newClientId(),
          'reason': _reason.text.trim(),
          'supplier_name': _supplier.text.trim(),
          'invoice_no': _invoice.text.trim(),
          'notes': _notes.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                const Text('1. Select Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _batchId,
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
                  onChanged: (v) => setState(() => _batchId = v),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('2. Stock Adjustment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _action,
                  items: const [
                    DropdownMenuItem(value: 'add', child: Text('Add Stock (+)')),
                    DropdownMenuItem(value: 'remove', child: Text('Remove Stock (−)')),
                    DropdownMenuItem(value: 'adjust', child: Text('Set Absolute Qty')),
                    DropdownMenuItem(value: 'disposal', child: Text('Disposal')),
                    DropdownMenuItem(value: 'return', child: Text('Return to Supplier')),
                  ],
                  onChanged: (v) => setState(() => _action = v ?? 'add'),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (selected != null) ...[
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
                const Text('3. Traceability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _supplier,
                  decoration: const InputDecoration(
                    labelText: 'Supplier / Source',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invoice,
                  decoration: const InputDecoration(
                    labelText: 'Invoice / PO',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
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
