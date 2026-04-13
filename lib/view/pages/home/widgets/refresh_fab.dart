import 'package:fast_bridge_front/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';

class RefreshFab extends StatelessWidget {
  const RefreshFab({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Refresh devices',
      onPressed: () async {
        await viewModel.getDevices();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Device list refreshed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: const Icon(Icons.refresh_rounded, size: 26),
    );
  }
}
