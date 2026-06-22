import 'package:future_ai/src/models/screen_model.dart';

class ProjectModel {
  final String id;
  final String ownerId;
  String title;
  String description;
  DateTime createdAt;
  List<ScreenModel> screens;

  ProjectModel({required this.id, required this.ownerId, required this.title, this.description = '', DateTime? createdAt, List<ScreenModel>? screens})
      : createdAt = createdAt ?? DateTime.now(),
        screens = screens ?? [ScreenModel(id: 'screen_1', name: 'Home')];

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'screens': screens.map((s) => s.toMap()).toList(),
      };

  factory ProjectModel.fromMap(Map<String, dynamic> m) => ProjectModel(
        id: m['id'] ?? '',
        ownerId: m['ownerId'] ?? '',
        title: m['title'] ?? 'Untitled',
        description: m['description'] ?? '',
        createdAt: DateTime.parse(m['createdAt'] ?? DateTime.now().toIso8601String()),
        screens: (m['screens'] as List? ?? []).map((e) => ScreenModel.fromMap(Map<String, dynamic>.from(e))).toList(),
      );
}
