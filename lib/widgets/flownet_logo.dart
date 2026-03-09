import 'package:flutter/material.dart';

class FlownetLogo extends StatelessWidget {
  const FlownetLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Icons/Red_Khono_Discs.png',
      width: 32,
      height: 32,
      fit: BoxFit.contain,
    );
  }
}