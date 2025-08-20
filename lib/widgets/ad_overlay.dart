// Simulated interstitial ad overlay
import 'dart:async';
import 'package:flutter/material.dart';

class AdOverlay {
  static Future<void> show(BuildContext context, {int seconds = 3, required String label}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdDialog(seconds: seconds, label: label),
    );
  }
}

class _AdDialog extends StatefulWidget {
  final int seconds; final String label;
  const _AdDialog({required this.seconds, required this.label});
  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late int _left;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _left = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Advertisement', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(widget.label),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text('Closing in $_left s'),
          ],
        ),
      ),
    );
  }
}
