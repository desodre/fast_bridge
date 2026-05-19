import 'package:xml/xml.dart';

class UiHierarchy {
  final List<UiNode> nodes;

  UiHierarchy({required this.nodes});

  factory UiHierarchy.fromXmlString(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final hierarchyElements = document.findAllElements('hierarchy');
    if (hierarchyElements.isEmpty) {
      throw const FormatException('Invalid hierarchy XML: missing <hierarchy>');
    }
    final hierarchyElement = hierarchyElements.first;

    return UiHierarchy(
      nodes: hierarchyElement.childElements
          .where((element) => element.name.local == 'node')
          .map(UiNode.fromXmlElement)
          .toList(),
    );
  }
}

class UiNode {
  final int index;
  final String text;
  final String className;
  final String resourceId;
  final Bounds bounds;
  final List<UiNode> children;

  UiNode({
    required this.index,
    required this.text,
    required this.className,
    required this.resourceId,
    required this.bounds,
    required this.children,
  });

  factory UiNode.fromXmlElement(XmlElement element) {
    return UiNode(
      index: int.tryParse(element.getAttribute('index') ?? '0') ?? 0,
      text: element.getAttribute('text') ?? '',
      className: element.getAttribute('class') ?? '',
      resourceId: element.getAttribute('resource-id') ?? '',
      bounds: Bounds.fromString(element.getAttribute('bounds') ?? '[0,0][0,0]'),
      children: element.childElements
          .where((child) => child.name.local == 'node')
          .map(UiNode.fromXmlElement)
          .toList(),
    );
  }
}

class Bounds {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  const Bounds({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  double get width => (x2 - x1).toDouble();
  double get height => (y2 - y1).toDouble();
  List<int> toList() => [x1, y1, x2, y2];

  factory Bounds.fromString(String value) {
    final parsed = parseBoundsValues(value);
    return Bounds(x1: parsed[0], y1: parsed[1], x2: parsed[2], y2: parsed[3]);
  }
}

List<int> parseBoundsValues(String value) {
  final match = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]').firstMatch(value);
  if (match == null) {
    return const [0, 0, 0, 0];
  }

  return [
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
  ];
}
