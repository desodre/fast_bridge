import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:fast_bridge_front/view/pages/home/store/device_store.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/float_button_fetch.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final deviceStore = DeviceStore();
  final _repository = DeviceRepository();

  @override
  void initState() {
    super.initState();
    deviceStore.getDevices();
    deviceStore.devices.addListener(() {
      setState(() {});
    });
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final ok = await _repository.healthCheck();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: ok ? const Color(0xDD2E7D32) : const Color(0xDDB71C1C),
        duration: Duration(seconds: ok ? 2 : 5),
        content: Row(
          children: [
            Icon(ok ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ok ? 'Backend online' : 'Backend offline — verifique se o servidor está rodando',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        action: ok
            ? null
            : SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _checkHealth),
      ),
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
            Icon(Icons.cable_rounded, color: theme.colorScheme.primary, size: 24),
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
      floatingActionButton: FloatButtonFetch(deviceStore: deviceStore),
      body: _DeviceList(
        devices: deviceStore.devices.value,
        isLoading: deviceStore.isLoading,
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.devices, required this.isLoading});
  final List<DeviceInfo> devices;
  final ValueNotifier<bool> isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: isLoading,
      builder: (context, loading, _) {
        if (loading && devices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phonelink_off_rounded, size: 56, color: theme.colorScheme.primary.withAlpha(120)),
                const SizedBox(height: 16),
                Text('No devices found', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Connect a device via USB and tap refresh', style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: devices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _DeviceCard(device: devices[index]),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = device.state == 'device';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/device/${device.serialNo}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone_android_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.serialNo, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 3),
                    Text(device.devPath, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? Colors.green : Colors.orange).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      device.state,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOnline ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}