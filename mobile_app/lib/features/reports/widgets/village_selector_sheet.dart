import 'package:flutter/material.dart';

class VillageSelectorSheet extends StatelessWidget {
  final String selectedVillage;
  final Function(String) onVillageSelected;

  const VillageSelectorSheet({
    super.key,
    required this.selectedVillage,
    required this.onVillageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> villages = ['Rampur', 'Kaman', 'Shiv Nagar', 'Lakshmi Nagar'];
    const Color primaryColor = Color(0xFF2F4DB6);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select Village",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            itemCount: villages.length,
            itemBuilder: (context, index) {
              final village = villages[index];
              final isSelected = village == selectedVillage;
              return ListTile(
                leading: Icon(
                  Icons.location_on_outlined,
                  color: isSelected ? primaryColor : Colors.grey[400],
                ),
                title: Text(
                  village,
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: primaryColor) : null,
                onTap: () {
                  onVillageSelected(village);
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
