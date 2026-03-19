class AdbExecution {
  final String deviceSerial;
  final String stdout;
  final int exitCode;

  AdbExecution({
    required this.deviceSerial,
    required this.stdout,
    required this.exitCode,
  });

  factory AdbExecution.fromJson(Map<String, dynamic> json) {
    return AdbExecution(
      deviceSerial: json['device_serial'],
      stdout: json['stdout'],
      exitCode: int.parse(json['exit_code']),
    );
  }
}
