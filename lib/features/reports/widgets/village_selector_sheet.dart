import 'package:flutter/material.dart';

class VillageSelectorSheet extends StatelessWidget {
  final Function(String) onVillageSelected;
  final String currentVillage;

  const VillageSelectorSheet({
    super.key,
    required this.onVillageSelected,
    required this.currentVillage,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> villages = [
      'Rampur',
      'Kaman',
      'Shiv Nagar',
      'Lakshmi Nagar',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "Select Village",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(),
          ...villages.map(
            (village) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                Icons.location_on_outlined,
                color: village == currentVillage
                    ? const Color(0xFF2F4DB6)
                    : Colors.grey,
              ),
              title: Text(
                "$village Village",
                style: TextStyle(
                  fontWeight: village == currentVillage
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: village == currentVillage
                      ? const Color(0xFF2F4DB6)
                      : Colors.black87,
                ),
              ),
              trailing: village == currentVillage
                  ? const Icon(Icons.check_circle, color: Color(0xFF2F4DB6))
                  : null,
              onTap: () {
                onVillageSelected(village);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
