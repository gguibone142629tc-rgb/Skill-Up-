import 'package:flutter/material.dart';

class LoadingDialog {
  static void show(BuildContext context, {String? message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(color: Colors.white))
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<void> navigateWithLoader(
    BuildContext context,
    Widget page, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    show(context);
    await Future.delayed(delay);
    hide(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
