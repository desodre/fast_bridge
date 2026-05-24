import 'dart:async';
import 'package:adb_utils/adb_utils.dart';
import 'package:fast_bridge_front/view/ui/toast_service.dart';
import 'package:fast_bridge_front/viewmodel/device_viewmodel.dart';

class DeviceMonitorService {
  final AdbClient _adbClient = AdbClient();
  StreamSubscription<DeviceEvent>? _subscription;

  /// Inicia o monitoramento em segundo plano
  void startMonitoring() {
    // Escuta a stream de eventos de dispositivos
    _subscription = _adbClient.trackDevices().listen(
      (DeviceEvent event) {
        switch (event.state) {
          case DeviceState.offline:
            _mostrarAviso(
              titulo: 'Dispositivo Offline',
              mensagem: 'O dispositivo ${event.serial} está offline.',
              tipo: AvisoTipo.erro,
            );
            break;
          case DeviceState.unauthorized:
            _mostrarAviso(
              titulo: 'Dispositivo Não Autorizado',
              mensagem: 'O dispositivo ${event.serial} não está autorizado. Verifique a autorização no dispositivo.',
              tipo: AvisoTipo.erro,
            );
            break;
          case DeviceState.device:
            _mostrarAviso(
              titulo: 'Dispositivo Conectado',
              mensagem: 'O dispositivo ${event.serial} foi conectado.',
              tipo: AvisoTipo.sucesso,
            );
            break;
          case DeviceState.recovery:
            _mostrarAviso(
              titulo: 'Dispositivo em Modo Recovery',
              mensagem: 'O dispositivo ${event.serial} está em modo recovery.',
              tipo: AvisoTipo.erro,
            );
            break;
          case DeviceState.unknown:
            _mostrarAviso(
              titulo: 'Estado Desconecido',
              mensagem: 'O dispositivo ${event.serial} está em um estado desconhecido.',
              tipo: AvisoTipo.erro,);
            break;
        }
      },
      onError: (error) {
        _mostrarAviso(
          titulo: 'Erro no Monitoramento',
          mensagem: 'Ocorreu um erro ao monitorar os dispositivos: $error',
          tipo: AvisoTipo.erro,
        );
        _reiniciarMonitoramento();
      },

    );
  }

  /// Integração com a Interface (Pop-ups)
  void _mostrarAviso({
    required String titulo, 
    required String mensagem, 
    required AvisoTipo tipo
  }) {
    if (tipo == AvisoTipo.sucesso) {
      ToastService.success(titulo, description: mensagem);
    } else {
      ToastService.error(titulo, description: mensagem);
    }
  }

  void _reiniciarMonitoramento() {
    _subscription?.cancel();
    Future.delayed(const Duration(seconds: 3), () {
      startMonitoring();
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}

enum AvisoTipo { sucesso, erro }