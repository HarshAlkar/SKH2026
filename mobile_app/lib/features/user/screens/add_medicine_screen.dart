import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medicine_model.dart';
import '../../../providers/medicine_provider.dart';

class AddMedicineScreen extends StatefulWidget {
  final DateTime? initialDate;
  final MedicineModel? medicine;
  const AddMedicineScreen({super.key, this.initialDate, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _timeController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedFrequency = 'Daily'; // 'Once' or 'Daily'
  List<String> _medicineSuggestions = [];
  bool _isLoading = false;

  bool get isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    _loadMedicineDataset();

    if (isEditing) {
      final med = widget.medicine!;
      _nameController.text = med.medicineName;
      _dosageController.text = med.dosage;
      _selectedFrequency = med.frequency.trim().toLowerCase() == 'once' ? 'Once' : 'Daily';
      _startDateController.text = med.startDate;
      _endDateController.text = med.endDate.isNotEmpty ? med.endDate : med.startDate;
      _timeController.text = med.reminderTime;
      _instructionsController.text = med.instructions;
    } else {
      final defaultDate = widget.initialDate ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(defaultDate);
      _startDateController.text = dateStr;
      _endDateController.text = dateStr;
    }
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isOnce = false}) async {
    DateTime initial = widget.initialDate ?? DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initial = DateFormat('yyyy-MM-dd').parse(controller.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        controller.text = formatted;
        if (isOnce || _selectedFrequency == 'Once') {
          _startDateController.text = formatted;
          _endDateController.text = formatted;
        }
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
      final startDate = _startDateController.text.trim();
      final endDate = _selectedFrequency == 'Once' ? startDate : _endDateController.text.trim();

      if (isEditing) {
        final updatedMed = MedicineModel(
          id: widget.medicine!.id,
          medicineName: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _selectedFrequency,
          startDate: startDate,
          endDate: endDate,
          reminderTime: _timeController.text.trim(),
          instructions: _instructionsController.text.trim(),
          isTaken: widget.medicine!.isTaken,
          createdAt: widget.medicine!.createdAt,
        );

        await context.read<MedicineProvider>().updateMedicine(updatedMed);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newMed = MedicineModel(
          medicineName: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _selectedFrequency,
          startDate: startDate,
          endDate: endDate,
          reminderTime: _timeController.text.trim(),
          instructions: _instructionsController.text.trim(),
          createdAt: DateTime.now(),
        );

        await context.read<MedicineProvider>().addMedicine(newMed);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine added successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(
                isEditing ? 'Edit Medicine Details' : 'Medicine Details',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 24),
              
              // Autocomplete Medicine Name
              const Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
              _buildField('Dosage', 'e.g. 1 Tablet / 5ml', _dosageController),
              
              const SizedBox(height: 20),
              // Frequency Selection
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFrequency = 'Once';
                          _endDateController.text = _startDateController.text;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedFrequency == 'Once' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFrequency == 'Once' ? AppColors.primary : Colors.grey.shade200,
                            width: _selectedFrequency == 'Once' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFrequency == 'Once' ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: _selectedFrequency == 'Once' ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Once',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedFrequency == 'Once' ? AppColors.primary : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedFrequency = 'Daily'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedFrequency == 'Daily' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFrequency == 'Daily' ? AppColors.primary : Colors.grey.shade200,
                            width: _selectedFrequency == 'Daily' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFrequency == 'Daily' ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: _selectedFrequency == 'Daily' ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Daily',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedFrequency == 'Daily' ? AppColors.primary : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              // Dates based on Frequency
              if (_selectedFrequency == 'Once')
                _buildClickableField(
                  'Date',
                  _startDateController,
                  () => _selectDate(context, _startDateController, isOnce: true),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildClickableField(
                        'Start Date',
                        _startDateController,
                        () => _selectDate(context, _startDateController),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildClickableField(
                        'End Date',
                        _endDateController,
                        () => _selectDate(context, _endDateController),
                      ),
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
                      : Text(isEditing ? 'Update Schedule' : 'Save Schedule', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
