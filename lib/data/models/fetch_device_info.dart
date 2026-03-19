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

  DeviceInfo({required this.serialNo, required this.devPath, required this.state});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      serialNo: json['serialno'],
      devPath: json['devpath'],
      state: json['state'],
    );
  }
}
