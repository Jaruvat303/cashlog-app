import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Full-screen pinch-zoom/pan viewer for a slip thumbnail (spec: "แตะเพื่อดูสลิป
/// ... pinch-zoom/pan ... ปุ่มปิด"). Presented via [showDialog] rather than a
/// new named/go_router route — the caller's page stays mounted underneath,
/// so its form state is never touched by opening or closing this.
Future<void> showFullScreenImageViewer(BuildContext context, Uint8List bytes) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => _FullScreenImageViewer(bytes: bytes),
  );
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.memory(bytes),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: SafeArea(
              child: IconButton(
                key: const Key('closeFullScreenSlipViewer'),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
