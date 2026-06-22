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
  int currentScreenIndex = 0;
  List<ProjectModel> myProjects = [];

  @override
  void initState() {
    super.initState();
    _loadMyProjects();
  }

  Future<void> _loadMyProjects() async {
    try {
      final user = FirebaseService.instance.currentUser;
      if (user == null) return;
      final q = await FirebaseService.instance.projectsCollection().where('ownerId', isEqualTo: user.uid).get();
      final list = q.docs.map((d) => ProjectModel.fromMap(Map<String, dynamic>.from(d.data()))).toList();
      setState(() {
        myProjects = list;
      });
    } catch (e) {
      // ignore for now
    }
  }

  Future<void> _createNewProject() async {
    final user = FirebaseService.instance.currentUser;
    final id = uuid.v4();
    final proj = ProjectModel(id: id, ownerId: user?.uid ?? 'anonymous', title: 'New Project');
    await FirebaseService.instance.projectsCollection().doc(id).set(proj.toMap());
    setState(() {
      project = proj;
      editorNotifier = EditorNotifier(proj.screens.first);
      currentScreenIndex = 0;
      myProjects.insert(0, proj);
    });
  }

  Future<void> _openProject(ProjectModel proj) async {
    setState(() {
      project = proj;
      currentScreenIndex = 0;
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
    await _loadMyProjects();
  }

  void _addScreen() {
    if (project == null) return;
    final id = uuid.v4();
    final screen = ScreenModel(id: id, name: 'Screen ${project!.screens.length + 1}');
    project!.screens.add(screen);
    setState(() {
      currentScreenIndex = project!.screens.length - 1;
      editorNotifier = EditorNotifier(project!.screens[currentScreenIndex]);
    });
  }

  void _switchToScreen(int index) {
    if (project == null) return;
    final s = project!.screens[index];
    setState(() {
      currentScreenIndex = index;
      editorNotifier = EditorNotifier(s);
    });
  }

  Future<void> _exportProject() async {
    if (project == null) return;
    // Call backend to export multi-screen zip
    // This requires the backend to be running and accessible
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export requested (backend should handle ZIP generation).')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI App Builder'),
        actions: [
          IconButton(onPressed: _createNewProject, icon: const Icon(Icons.add_box)),
          IconButton(onPressed: _saveProject, icon: const Icon(Icons.save)),
          IconButton(onPressed: _exportProject, icon: const Icon(Icons.download)),
        ],
      ),
      body: Row(children: [
        // Left: Projects list and components
        SizedBox(
          width: 260,
          child: Column(children: [
            Container(padding: const EdgeInsets.all(8), child: const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: myProjects.isEmpty
                  ? const Center(child: Text('No projects found'))
                  : ListView.builder(
                      itemCount: myProjects.length,
                      itemBuilder: (context, idx) {
                        final p = myProjects[idx];
                        return ListTile(
                          title: Text(p.title),
                          subtitle: Text('Screens: ${p.screens.length}'),
                          onTap: () => _openProject(p),
                        );
                      },
                    ),
            ),
            const Divider(),
            const ListTile(title: Text('Components', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.smart_button),
                    title: const Text('Button'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'button', left: 50, top: 50, width: 120, height: 48, props: {'text': 'Button'});
                      editorNotifier?.addComponent(comp);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    title: const Text('Text'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'text', left: 60, top: 120, width: 160, height: 30, props: {'text': 'Hello'});
                      editorNotifier?.addComponent(comp);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Image'),
                    onTap: () {
                      final comp = ComponentModel(id: uuid.v4(), type: 'image', left: 80, top: 180, width: 120, height: 80, props: {'url': ''});
                      editorNotifier?.addComponent(comp);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),

        // Center: Canvas and screen tabs
        Expanded(
          flex: 2,
          child: Column(children: [
            // Screen tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                if (project != null)
                  for (var i = 0; i < project!.screens.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(project!.screens[i].name),
                        selected: i == currentScreenIndex,
                        onSelected: (_) => _switchToScreen(i),
                      ),
                    ),
                TextButton.icon(onPressed: _addScreen, icon: const Icon(Icons.add), label: const Text('Add Screen')),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
                child: Builder(builder: (context) {
                  if (project == null || editorNotifier == null) {
                    return const Center(child: Text('Open or create a project to start building'));
                  }
                  final editor = editorNotifier!;
                  return Stack(
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
                  );
                }),
              ),
            ),
          ]),
        ),

        // Right: Properties panel
        SizedBox(
          width: 320,
          child: Column(children: [
            const ListTile(title: Text('Properties')),
            Expanded(
              child: editorNotifier == null || editorNotifier!.state.selectedId == null
                  ? const Center(child: Text('Select a component'))
                  : _propertiesPanel(editorNotifier!.state.screen.components.firstWhere((e) => e.id == editorNotifier!.state.selectedId), editorNotifier!),
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
      child: SingleChildScrollView(
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
            TextField(
              controller: textCtrl,
              onChanged: (v) {
                final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'text': v});
                editor.updateComponent(updated);
                setState(() {});
              },
            ),
          ],
          if (type == 'image') ...[
            const Text('Image URL'),
            TextField(
              controller: urlCtrl,
              onChanged: (v) {
                final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'url': v});
                editor.updateComponent(updated);
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: () { editor.removeComponent(c.id); setState(() {}); }, icon: const Icon(Icons.delete), label: const Text('Delete')),
        ]),
      ),
    );
  }
}
