import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled; 

  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.enabled = true, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(243, 255, 255, 255),
          foregroundColor: enabled ? color : Colors.grey, // 버턴 회색처리
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: (enabled ? color : Colors.grey).withAlpha(128)),
          ),
          elevation: enabled ? 2 : 0,
        ),
        onPressed: enabled ? onPressed : null, // 회색 클릭 금지
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
