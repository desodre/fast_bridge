class ScreenInfo {
  final int width;
  final int height;

  ScreenInfo({required this.width, required this.height});

  factory ScreenInfo.fromJson(Map<String, dynamic> json) {
    return ScreenInfo(
      width: json['width'],
      height: json['height'],
    );
  }
}