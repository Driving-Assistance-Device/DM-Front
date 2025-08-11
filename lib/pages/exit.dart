import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmExitWrapper extends StatelessWidget {
  final Widget child;
  const ConfirmExitWrapper({super.key, required this.child});

  Future<bool> _onWillPop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('정말 종료하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('종료', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
    }
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        bool shouldExit = await _onWillPop(context);
        if (shouldExit) {
          Navigator.of(context).pop(result); 
        }
      },
      child: child,
    );
  }
}
