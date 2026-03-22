import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hs053/core/theme/app_colors.dart';
import 'package:hs053/shared/models/medicine_model.dart';
import 'package:hs053/shared/providers/medicine_provider.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _timeController = TextEditingController();
  final _instructionsController = TextEditingController();

  List<String> _medicineSuggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicineDataset();
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _endDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)));
  }

  Future<void> _loadMedicineDataset() async {
    try {
      final String response = await rootBundle.loadString('lib/dataset/medicine_dataset/medicines.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _medicineSuggestions = data.map((item) => item['name'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading dataset: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newMed = MedicineModel(
        medicineName: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequencyController.text,
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        reminderTime: _timeController.text,
        instructions: _instructionsController.text,
        createdAt: DateTime.now(),
      );

      await context.read<MedicineProvider>().addMedicine(newMed);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medicine Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Autocomplete Medicine Name
              const Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return _medicineSuggestions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _nameController.text = val,
                    decoration: _inputDecoration('e.g. Paracetamol'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  );
                },
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildField('Dosage', 'e.g. 1 Tablet', _dosageController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Frequency', 'e.g. Twice Daily', _frequencyController)),
                ],
              ),
              
              const SizedBox(height: 20),
              Row(
                children: [
                   Expanded(
                    child: _buildClickableField('Start Date', _startDateController, () => _selectDate(context, _startDateController)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildClickableField('End Date', _endDateController, () => _selectDate(context, _endDateController)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildClickableField('Reminder Time', _timeController, () => _selectTime(context), icon: Icons.access_time),
              
              const SizedBox(height: 20),
              _buildField('Special Instructions', 'e.g. After food', _instructionsController, maxLines: 3),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Save Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildClickableField(String label, TextEditingController controller, VoidCallback onTap, {IconData icon = Icons.calendar_today}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              decoration: _inputDecoration('Select').copyWith(
                suffixIcon: Icon(icon, color: AppColors.primary, size: 20),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
          ),
        ),
      ],
    );
  }
}
