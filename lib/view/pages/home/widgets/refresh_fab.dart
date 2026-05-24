import 'package:fast_bridge_front/viewmodel/home_viewmodel.dart';
import 'package:fast_bridge_front/view/ui/toast_service.dart';
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
        ToastService.info('Device list refreshed', context: context);
      },
      child: const Icon(Icons.refresh_rounded, size: 26),
    );
  }
}
