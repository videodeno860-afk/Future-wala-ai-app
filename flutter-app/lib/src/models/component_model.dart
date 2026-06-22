import 'package:collection/collection.dart';

class ComponentModel {
  final String id;
  String type; // 'button', 'text', 'image', 'container'
  double left;
  double top;
  double width;
  double height;
  Map<String, dynamic> props;

  ComponentModel({
    required this.id,
    required this.type,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    Map<String, dynamic>? props,
  }) : props = props ?? {};

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'props': props,
      };

  factory ComponentModel.fromMap(Map<String, dynamic> m) => ComponentModel(
        id: m['id'] ?? '',
        type: m['type'] ?? 'container',
        left: (m['left'] ?? 0).toDouble(),
        top: (m['top'] ?? 0).toDouble(),
        width: (m['width'] ?? 100).toDouble(),
        height: (m['height'] ?? 40).toDouble(),
        props: Map<String, dynamic>.from(m['props'] ?? {}),
      );
}
