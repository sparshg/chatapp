import 'package:flutter/material.dart';

class Styles {
  static InputDecoration textDecoration(String hint) => InputDecoration(
        hintText: hint,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
        contentPadding: const EdgeInsets.all(20),
      );

  static const _rounded = 28.0;

  static final buttonDecoration = OutlinedButton.styleFrom(
    shape: const StadiumBorder(),
    side: BorderSide(color: Colors.grey.shade700),
  );
  static const topListBorder = BorderRadius.vertical(
    top: Radius.circular(_rounded),
  );
  static const bottomListBorder = BorderRadius.vertical(
    bottom: Radius.circular(_rounded),
  );
  static const roundedListBorder = BorderRadius.all(Radius.circular(_rounded));
}
