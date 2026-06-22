import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:future_ai/src/models/project_model.dart';
import 'package:future_ai/src/models/screen_model.dart';
import 'package:future_ai/src/models/component_model.dart';
import 'package:future_ai/src/state/editor_state.dart';
import 'package:future_ai/src/services/firebase_service.dart';

final uuid = Uuid();

class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen> {
  ProjectModel? project;
  EditorNotifier? editorNotifier;

  @override
  void initState() {
    super.initState();
    // For demo: load or create a project in-memory; real app should list projects and open one
  }

  Future<void> _createNewProject() async {
    final user = FirebaseService.instance.currentUser;
    final id = uuid.v4();
    final proj = ProjectModel(id: id, ownerId: user?.uid ?? 'anonymous', title: 'New Project');
    await FirebaseService.instance.projectsCollection().doc(id).set(proj.toMap());
    setState(() {
      project = proj;
      editorNotifier = EditorNotifier(proj.screens.first);
    });
  }

  Future<void> _loadProject(String id) async {
    final snap = await FirebaseService.instance.projectsCollection().doc(id).get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;
    final proj = ProjectModel.fromMap(Map<String, dynamic>.from(data));
    setState(() {
      project = proj;
      editorNotifier = EditorNotifier(proj.screens.first);
    });
  }

  Future<void> _saveProject() async {
    if (project == null || editorNotifier == null) return;
    final currentScreen = editorNotifier!.state.screen;
    final screens = project!.screens.map((s) => s.id == currentScreen.id ? currentScreen : s).toList();
    project = ProjectModel(id: project!.id, ownerId: project!.ownerId, title: project!.title, description: project!.description, createdAt: project!.createdAt, screens: screens);
    await FirebaseService.instance.projectsCollection().doc(project!.id).set(project!.toMap());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI App Builder')),
        body: Center(
          child: ElevatedButton(onPressed: _createNewProject, child: const Text('Create New Project')),
        ),
      );
    }
    final editor = editorNotifier!;
    return Scaffold(
      appBar: AppBar(
        title: Text(project!.title),
        actions: [
          IconButton(onPressed: _saveProject, icon: const Icon(Icons.save)),
          IconButton(onPressed: () => editor.undo(), icon: const Icon(Icons.undo)),
          IconButton(onPressed: () => editor.redo(), icon: const Icon(Icons.redo)),
        ],
      ),
      body: Row(children: [
        SizedBox(
          width: 220,
          child: Column(children: [
            const ListTile(title: Text('Components')),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.smart_button),
                    title: const Text('Button'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'button', left: 50, top: 50, width: 120, height: 48, props: {'text': 'Button'});
                      editor.addComponent(comp);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    title: const Text('Text'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'text', left: 60, top: 120, width: 160, height: 30, props: {'text': 'Hello'});
                      editor.addComponent(comp);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Image'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'image', left: 80, top: 180, width: 120, height: 80, props: {'url': ''});
                      editor.addComponent(comp);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
            child: Stack(
              children: editor.state.screen.components.map((c) {
                return Positioned(
                  left: c.left,
                  top: c.top,
                  child: GestureDetector(
                    onTap: () {
                      editor.select(c.id);
                      setState(() {});
                    },
                    onPanUpdate: (details) {
                      final updated = ComponentModel(id: c.id, type: c.type, left: c.left + details.delta.dx, top: c.top + details.delta.dy, width: c.width, height: c.height, props: c.props);
                      editor.updateComponent(updated);
                      setState(() {});
                    },
                    child: _renderComponent(c, editor.state.selectedId == c.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: Column(children: [
            const ListTile(title: Text('Properties')),
            Expanded(
              child: editor.state.selectedId == null
                  ? const Center(child: Text('Select a component'))
                  : _propertiesPanel(editor.state.screen.components.firstWhere((e) => e.id == editor.state.selectedId), editor),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _renderComponent(ComponentModel c, bool selected) {
    final border = selected ? Border.all(color: Colors.blue, width: 2) : Border.all(color: Colors.transparent);
    switch (c.type) {
      case 'button':
        return Container(
          width: c.width,
          height: c.height,
          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8), border: border),
          alignment: Alignment.center,
          child: Text(c.props['text'] ?? 'Button', style: const TextStyle(color: Colors.white)),
        );
      case 'text':
        return Container(
          width: c.width,
          height: c.height,
          decoration: BoxDecoration(border: border),
          child: Text(c.props['text'] ?? 'Text'),
        );
      case 'image':
        return Container(
          width: c.width,
          height: c.height,
          decoration: BoxDecoration(color: Colors.grey.shade300, border: border),
          child: c.props['url'] == null || c.props['url'] == '' ? const Icon(Icons.image) : Image.network(c.props['url'], fit: BoxFit.cover),
        );
      default:
        return Container(width: c.width, height: c.height, decoration: BoxDecoration(border: border, color: Colors.white));
    }
  }

  Widget _propertiesPanel(ComponentModel c, EditorNotifier editor) {
    final type = c.type;
    final textCtrl = TextEditingController(text: c.props['text']?.toString() ?? '');
    final urlCtrl = TextEditingController(text: c.props['url']?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Type: $type', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Position'),
        Row(children: [
          Expanded(child: Text('x: ${c.left.toStringAsFixed(0)}')),
          Expanded(child: Text('y: ${c.top.toStringAsFixed(0)}')),
        ]),
        const SizedBox(height: 12),
        if (type == 'button' || type == 'text') ...[
          const Text('Text'),
          TextField(controller: textCtrl, onSubmitted: (v) {
            final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'text': v});
            editor.updateComponent(updated);
            setState(() {});
          }),
        ],
        if (type == 'image') ...[
          const Text('Image URL'),
          TextField(controller: urlCtrl, onSubmitted: (v) {
            final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'url': v});
            editor.updateComponent(updated);
            setState(() {});
          }),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () { editor.removeComponent(c.id); setState(() {}); }, icon: const Icon(Icons.delete), label: const Text('Delete')),
      ]),
    );
  }
}
