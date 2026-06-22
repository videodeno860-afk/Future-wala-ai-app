import 'package:future_ai/src/models/component_model.dart';

class ScreenModel {
  final String id;
  String name;
  List<ComponentModel> components;

  ScreenModel({required this.id, required this.name, List<ComponentModel>? components}) : components = components ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'components': components.map((c) => c.toMap()).toList(),
      };

  factory ScreenModel.fromMap(Map<String, dynamic> m) => ScreenModel(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Screen',
        components: (m['components'] as List? ?? []).map((e) => ComponentModel.fromMap(Map<String, dynamic>.from(e))).toList(),
      );
}
