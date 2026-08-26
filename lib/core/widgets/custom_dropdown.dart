import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?)? onChanged;
  final IconData prefixIcon;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    this.onChanged,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B3B5A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1B3B5A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      items: items,
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'يرجى اختيار عنصر' : null,
    );
  }
}