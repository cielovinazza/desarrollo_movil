import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClienteTextField
    extends StatelessWidget {

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  final String? Function(String?)?
      validator;

  const ClienteTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType =
        TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization =TextCapitalization.none,
    this.inputFormatters,

  });

  @override
  Widget build(BuildContext context) {

    return TextFormField(

      controller: controller,

      keyboardType: keyboardType,

      maxLines: maxLines,

      validator: validator,

      textCapitalization: textCapitalization,

      inputFormatters: inputFormatters,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
            const OutlineInputBorder(),
        alignLabelWithHint:
            maxLines > 1,
      ),
    );
  }
}