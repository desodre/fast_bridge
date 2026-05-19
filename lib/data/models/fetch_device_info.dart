class FetchDeviceInfo {
  final List<DeviceInfo> deviceInfos;

  FetchDeviceInfo({required this.deviceInfos});

  factory FetchDeviceInfo.fromList(List<dynamic> list) {
    return FetchDeviceInfo(
      deviceInfos: list.map((e) => DeviceInfo.fromJson(e)).toList(),
    );
  }
}

class DeviceInfo {
  final String serialNo;
  final String devPath;
  final String state;

  DeviceInfo({
    required this.serialNo,
    required this.devPath,
    required this.state,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      serialNo: json['serialno'],
      devPath: json['devpath'],
      state: json['state'],
    );
  }

  factory DeviceInfo.fromAdb({
    required String serial,
    required String state,
    String? product,
    String? model,
    String? device,
  }) {
    final descriptor = [
      model,
      product,
      device,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return DeviceInfo(
      serialNo: serial,
      devPath: descriptor.isEmpty ? 'Unknown device' : descriptor,
      state: state,
    );
  }
}
