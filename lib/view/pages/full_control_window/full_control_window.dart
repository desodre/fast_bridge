import 'dart:developer' as dev;

import 'package:fast_bridge_front/view/pages/full_control_window/widgets/control_bar.dart';
import 'package:fast_bridge_front/view/pages/full_control_window/widgets/stream_view.dart';
import 'package:fast_bridge_front/view/widgets/loading_indicator.dart';
import 'package:fast_bridge_front/viewmodel/full_control_viewmodel.dart';
import 'package:flutter/material.dart';

class FullControlWindow extends StatefulWidget {
  const FullControlWindow({super.key, required this.serial});
  final String serial;

  @override
  State<FullControlWindow> createState() => _FullControlWindowState();
}

class _FullControlWindowState extends State<FullControlWindow> {
  late final FullControlViewModel _viewModel;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = FullControlViewModel(serial: widget.serial);
    _viewModel.connect();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSendText(String text) {
    final messenger = ScaffoldMessenger.of(context);
    _viewModel.sendText(text).catchError((e) {
      dev.log('Failed to send text: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send text: $e')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cast_connected_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(widget.serial, style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          ValueListenableBuilder<ConnState>(
            valueListenable: _viewModel.state,
            builder: (context, state, _) {
              final isLive = state == ConnState.streaming;
              final color = isLive ? Colors.green : Colors.red;
              return Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'Live' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<ConnState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ConnState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    switch (state) {
      case ConnState.idle:
      case ConnState.fetchingInfo:
        return const LoadingIndicator(message: 'Getting device info...');
      case ConnState.connectingWs:
        return const LoadingIndicator(message: 'Connecting to device stream...');
      case ConnState.error:
        return ValueListenableBuilder<String?>(
          valueListenable: _viewModel.error,
          builder: (context, errorMsg, _) {
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: cs.error,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        errorMsg ?? 'Unknown error',
                        style: TextStyle(color: cs.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _viewModel.connect,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      case ConnState.streaming:
        return Column(
          children: [
            Expanded(
              child: StreamView(
                frame: _viewModel.frame,
                onPointerDown: (pos, size) =>
                    _viewModel.sendTouch('touchDown', pos, size),
                onPointerMove: (pos, size) =>
                    _viewModel.sendTouch('touchMove', pos, size),
                onPointerUp: (pos, size) =>
                    _viewModel.sendTouch('touchUp', pos, size),
              ),
            ),
            ControlBar(
              onKeyEvent: _viewModel.sendKeyEvent,
              onSendText: _handleSendText,
              textController: _textController,
            ),
          ],
        );
    }
  }
}