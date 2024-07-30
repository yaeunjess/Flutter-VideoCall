import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final GestureTapCallback onPressed;
  final String text;

  const CustomElevatedButton({
    required this.onPressed,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[500],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
