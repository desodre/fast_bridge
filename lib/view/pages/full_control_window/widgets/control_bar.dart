import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    super.key,
    required this.onKeyEvent,
    required this.onSendText,
    required this.textController,
  });

  final void Function(int keycode) onKeyEvent;
  final void Function(String text) onSendText;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          _CtrlBtn(
            icon: Icons.arrow_back_rounded,
            tip: 'Back',
            onTap: () => onKeyEvent(4),
          ),
          _CtrlBtn(
            icon: Icons.circle_outlined,
            tip: 'Home',
            onTap: () => onKeyEvent(3),
          ),
          _CtrlBtn(
            icon: Icons.crop_square_rounded,
            tip: 'Recent',
            onTap: () => onKeyEvent(187),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: cs.primary.withAlpha(40),
          ),
          _CtrlBtn(
            icon: Icons.volume_down_rounded,
            tip: 'Vol −',
            onTap: () => onKeyEvent(25),
          ),
          _CtrlBtn(
            icon: Icons.volume_up_rounded,
            tip: 'Vol +',
            onTap: () => onKeyEvent(24),
          ),
          _CtrlBtn(
            icon: Icons.power_settings_new_rounded,
            tip: 'Power',
            onTap: () => onKeyEvent(26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: textController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type text...',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.send_rounded, size: 18, color: cs.primary),
                  onPressed: () {
                    onSendText(textController.text);
                    textController.clear();
                  },
                ),
              ),
              onSubmitted: (text) {
                onSendText(text);
                textController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({
    required this.icon,
    required this.tip,
    required this.onTap,
  });

  final IconData icon;
  final String tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}
