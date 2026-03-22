import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hs053/core/widgets/common_appbar.dart';
import 'package:hs053/core/routes/app_routes.dart';
import 'package:hs053/features/asha_worker/widgets/asha_drawer.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown_field.dart';
import 'package:hs053/core/services/api_service.dart';
import 'package:hs053/core/constants/api_constants.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}
  
class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _diseaseController = TextEditingController();

  // For the map lookup
  String _finalVillageName = "";

  String? _selectedGender;
  String? _selectedBloodGroup = "Not Known";

  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2F4DB6);
  final Color lightBackground = const Color(0xFFF5F7FA);

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  // Prevent API rate limit blocks
  Timer? _debounce;
  final Map<String, List<String>> _cache = {};

  Future<List<String>> _searchMapsVillages(String query) async {
    if (query.isEmpty || query.length < 3) return const [];
    
    if (_cache.containsKey(query)) return _cache[query]!;

    Completer<List<String>> completer = Completer();
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&countrycodes=in');
        final response = await http.get(url, headers: {'User-Agent': 'HackStompApp/1.0'});
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          if (data.isEmpty) {
             completer.complete([query]);
             return;
          }
          List<String> results = data.map((item) => item['display_name'].toString()).toList();
          _cache[query] = results;
          completer.complete(results);
          return;
        }
      } catch (_) {}
      completer.complete([query]); // Always allow manual entry if API rate limited
    });

    return completer.future;
  }

  void _handleSavePatient() async {
    if (_formKey.currentState!.validate()) {
      if (_finalVillageName.trim().isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or enter a valid village from the map dropdown.')),
         );
         return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final payload = {
          'name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'village': _finalVillageName, 
          'phone_number': _phoneController.text.trim(),
          'blood_group': _selectedBloodGroup,
          'disease': _diseaseController.text.trim(),
        };

        final response = await ApiService().post(ApiConstants.patientsEndpoint, body: payload);
        
        // Extract ABHA ID from user profile
        final abhaId = response['user']?['abha_id'] ?? 'N/A';

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          _showRegistrationSuccess(abhaId);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showRegistrationSuccess(String abhaId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('Registration Successful', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The patient has been registered. Here is their digital Health ID (ABHA).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: abhaId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                abhaId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F4DB6),
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildMapsAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Village (Search GPS Maps)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 3) {
              return const Iterable<String>.empty();
            }
            return await _searchMapsVillages(textEditingValue.text);
          },
          onSelected: (String selection) {
            setState(() {
              _finalVillageName = selection.trim();
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            controller.addListener(() {
              _finalVillageName = controller.text; 
            });

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              decoration: InputDecoration(
                hintText: "Type and wait for map suggestions...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.public, color: Color(0xFF2F4DB6)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2F4DB6), width: 1.5),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6.0,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 80, 
                  height: 200, 
                  child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                        title: Text(option, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: const CommonAppBar(
        title: "Register New Patient",
      ),
      drawer: const AshaDrawer(currentRoute: AppRoutes.registerPatient),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: "BASIC DETAILS",
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Full Name",
                        hintText: "Enter full name",
                        prefixIcon: Icons.person,
                        controller: _nameController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Full name cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: CustomInputField(
                              label: "Age",
                              hintText: "Years",
                              prefixIcon: Icons.calendar_today,
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Must be numeric';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: CustomDropdownField(
                              label: "Gender",
                              hintText: "Select",
                              items: const ["Male", "Female", "Other"],
                              value: _selectedGender,
                              onChanged: (val) =>
                                  setState(() => _selectedGender = val),
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildSectionCard(
                  title: "LOCATION & CONTACT",
                  child: Column(
                    children: [
                      _buildMapsAutocomplete(), 
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Phone Number",
                        hintText: "10-digit mobile number",
                        prefixIcon: Icons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (value.trim().length != 10) {
                            return 'Must be 10 digits';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Must be numeric';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                _buildSectionCard(
                  title: "MEDICAL HISTORY",
                  child: Column(
                    children: [
                      CustomDropdownField(
                        label: "Blood Group",
                        hintText: "Select blood group",
                        prefixIcon: Icons.favorite,
                        items: const [
                          "Not Known",
                          "A+",
                          "A-",
                          "B+",
                          "B-",
                          "O+",
                          "O-",
                          "AB+",
                          "AB-",
                        ],
                        value: _selectedBloodGroup,
                        onChanged: (val) =>
                            setState(() => _selectedBloodGroup = val),
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Existing Disease (if any)",
                        hintText: "Diabetes, Hypertension, etc.",
                        prefixIcon: Icons.info_outline,
                        controller: _diseaseController,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSavePatient,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Patient",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
