import 'package:fast_bridge_front/view/pages/home/home_page.dart';
import 'package:fast_bridge_front/view/pages/device_page/device_page.dart';
import 'package:fast_bridge_front/view/ui/theme.dart';
import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:developer' as dev;

// void startBackend() async {
//   try {
//     Process backProcess = await Process.start('./lib/exec/adb_sidecar_api', []);
//     dev.log("Backend started");
//     dev.log("Backend PID: ${backProcess.pid}");
//   } catch (e) {
//     dev.log('Erro ao inciar o back');
//     dev.log(e.toString());
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // startBackend();
  runApp(FastBridgeApp());
}

class FastBridgeApp extends StatelessWidget {
  const FastBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: customTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'device') {
          final serial = uri.pathSegments.last;

          return MaterialPageRoute(
            builder: (BuildContext context) => DevicePage(serial: serial),
            settings: settings, // Importante para manter o histórico
          );
        }

        return MaterialPageRoute(
          builder: (context) => HomePage(),
          settings: settings,
        );
      },
    );
  }
}
