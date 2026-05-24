import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/device_list.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/refresh_fab.dart';
import 'package:fast_bridge_front/view/ui/toast_service.dart';
import 'package:fast_bridge_front/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel _viewModel;
  final _repository = DeviceRepository();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.devices.addListener(() => setState(() {}));
    _viewModel.getDevices();
    _checkHealth();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    final ok = await _repository.healthCheck();
    if (!mounted) return;
    if (ok) {
      ToastService.success('ADB server online', context: context);
      return;
    }

    ToastService.error(
      'ADB server offline',
      description: 'Verifique se o adb está ativo',
      context: context,
      actionLabel: 'Retry',
      onAction: _checkHealth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cable_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Fast Bridge'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: RefreshFab(viewModel: _viewModel),
      body: DeviceList(
        devices: _viewModel.devices.value,
        isLoading: _viewModel.isLoading,
      ),
    );
  }
}
