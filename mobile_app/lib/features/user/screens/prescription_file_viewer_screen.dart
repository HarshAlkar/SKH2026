import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/prescription_file_cache.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen viewer for handwritten prescription images/PDFs via authenticated API.
class PrescriptionFileViewerScreen extends StatefulWidget {
  final int prescriptionId;
  final String? doctorName;
  final String? contentType;
  final String? note;
  final String? issuedAt;

  const PrescriptionFileViewerScreen({
    super.key,
    required this.prescriptionId,
    this.doctorName,
    this.contentType,
    this.note,
    this.issuedAt,
  });

  @override
  State<PrescriptionFileViewerScreen> createState() =>
      _PrescriptionFileViewerScreenState();
}

class _PrescriptionFileViewerScreenState
    extends State<PrescriptionFileViewerScreen> {
  final _api = ApiService();
  final _cache = PrescriptionFileCache.instance;

  bool _loading = true;
  String? _error;
  Uint8List? _bytes;
  String? _contentType;
  double _rotation = 0;
  bool _fromCache = false;

  bool get _isPdf {
    final ct = (_contentType ?? widget.contentType ?? '').toLowerCase();
    return ct.contains('pdf');
  }

  @override
  void initState() {
    super.initState();
    _contentType = widget.contentType;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await _cache.find(
      widget.prescriptionId,
      contentType: widget.contentType,
    );
    if (cached != null) {
      try {
        final bytes = await cached.readAsBytes();
        if (mounted) {
          setState(() {
            _bytes = bytes;
            _fromCache = true;
            _loading = false;
            if (_contentType == null || _contentType!.isEmpty) {
              _contentType = cached.path.toLowerCase().endsWith('.pdf')
                  ? 'application/pdf'
                  : 'image/jpeg';
            }
          });
        }
      } catch (_) {}
    }

    try {
      final bytes = await _api.getBytes(
        '/prescriptions/${widget.prescriptionId}/file/',
      );
      final ct = _contentType ?? widget.contentType ?? 'image/jpeg';
      await _cache.save(
        widget.prescriptionId,
        bytes,
        contentType: ct,
      );
      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(bytes);
        _contentType = ct;
        _fromCache = false;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_bytes != null) {
        setState(() {
          _loading = false;
          _fromCache = true;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error =
            'Prescription will be available when the record is synced.';
      });
    }
  }

  Future<void> _shareOrOpenPdf() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'prescription_${widget.prescriptionId}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doctorName?.isNotEmpty == true
                  ? widget.doctorName!
                  : 'Handwritten Prescription',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.issuedAt != null)
              Text(
                widget.issuedAt!,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (!_isPdf && _bytes != null)
            IconButton(
              tooltip: 'Rotate',
              icon: const Icon(Icons.rotate_right),
              onPressed: () => setState(() => _rotation = (_rotation + 90) % 360),
            ),
          if (_isPdf && _bytes != null)
            IconButton(
              tooltip: 'Open / Share PDF',
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareOrOpenPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null && _bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isPdf) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'PDF prescription',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_fromCache)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing securely cached copy',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              if (widget.note != null && widget.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _shareOrOpenPdf,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open / Share PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Transform.rotate(
              angle: _rotation * 3.1415926535 / 180,
              child: Image.memory(
                _bytes!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
        if (_loading)
          const Positioned(
            top: 12,
            right: 12,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
          ),
        if (_fromCache)
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              'Showing securely cached copy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        if (widget.note != null && widget.note!.trim().isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: _fromCache ? 48 : 24,
            child: Text(
              widget.note!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
