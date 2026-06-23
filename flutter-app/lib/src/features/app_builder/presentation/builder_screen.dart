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

class _BuilderScreenState extends ConsumerState<BuilderScreen> with SingleTickerProviderStateMixin {
  ProjectModel? project;
  EditorNotifier? editorNotifier;
  int currentScreenIndex = 0;
  List<ProjectModel> myProjects = [];
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _loadMyProjects();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export requested (backend should handle ZIP generation).')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI App Builder'),
        actions: [
          IconButton(onPressed: _createNewProject, icon: const Icon(Icons.create_new_folder)),
          IconButton(onPressed: _saveProject, icon: const Icon(Icons.save)),
          IconButton(onPressed: _exportProject, icon: const Icon(Icons.download)),
        ],
      ),
      body: Row(children: [
        // Left: Projects list and components (narrowed and polished)
        SizedBox(
          width: 280,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(children: [
              TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search projects', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              Expanded(
                child: myProjects.isEmpty
                    ? Center(child: Text('No projects', style: Theme.of(context).textTheme.bodyMedium))
                    : ListView.builder(
                        itemCount: myProjects.length,
                        itemBuilder: (context, idx) {
                          final p = myProjects[idx];
                          return GestureDetector(
                            onTap: () => _openProject(p),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: Text(p.title.isNotEmpty ? p.title[0] : '?', style: const TextStyle(color: Colors.white))),
                                title: Text(p.title),
                                subtitle: Text('${p.screens.length} screens'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: FloatingActionButton(onPressed: _createNewProject, child: const Icon(Icons.add))),
            ]),
          ),
        ),

        // Center: Canvas and screen tabs
        Expanded(
          flex: 2,
          child: Column(children: [
            // Screen tabs
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                if (project != null)
                  for (var i = 0; i < project!.screens.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(project!.screens[i].name),
                        selected: i == currentScreenIndex,
                        onSelected: (_) => _switchToScreen(i),
                        selectedColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                if (project == null) const Text('No project open', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                ElevatedButton.icon(onPressed: _addScreen, icon: const Icon(Icons.add), label: const Text('Add Screen')),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade200)),
                child: Builder(builder: (context) {
                  if (project == null || editorNotifier == null) {
                    return Center(child: Text('Open or create a project to start building', style: Theme.of(context).textTheme.titleMedium));
                  }
                  final editor = editorNotifier!;
                  return LayoutBuilder(builder: (context, constraints) {
                    // grid background
                    return Stack(children: [
                      CustomPaint(size: Size(constraints.maxWidth, constraints.maxHeight), painter: _GridPainter()),
                      ...editor.state.screen.components.map((c) {
                        return Positioned(
                          left: c.left,
                          top: c.top,
                          child: GestureDetector(
                            onTap: () { editor.select(c.id); setState(() {}); },
                            onPanUpdate: (details) {
                              final updated = ComponentModel(id: c.id, type: c.type, left: c.left + details.delta.dx, top: c.top + details.delta.dy, width: c.width, height: c.height, props: c.props);
                              editor.updateComponent(updated);
                              setState(() {});
                            },
                            child: _renderComponent(c, editor.state.selectedId == c.id),
                          ),
                        );
                      }).toList(),
                    ]);
                  });
                }),
              ),
            ),
          ]),
        ),

        // Right: Properties panel
        SizedBox(
          width: 360,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: editorNotifier == null || editorNotifier!.state.selectedId == null
                ? Center(child: Text('Select a component', style: Theme.of(context).textTheme.bodyLarge))
                : _propertiesPanel(editorNotifier!.state.screen.components.firstWhere((e) => e.id == editorNotifier!.state.selectedId), editorNotifier!),
          ),
        ),
      ]),
    );
  }

  Widget _renderComponent(ComponentModel c, bool selected) {
    final border = selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : Border.all(color: Colors.transparent);
    switch (c.type) {
      case 'button':
        return AnimatedContainer(duration: const Duration(milliseconds: 200), width: c.width, height: c.height, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8), border: border), alignment: Alignment.center, child: Text(c.props['text'] ?? 'Button', style: const TextStyle(color: Colors.white)));
      case 'text':
        return Container(width: c.width, height: c.height, padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: border), child: Text(c.props['text'] ?? 'Text'));
      case 'image':
        return Container(width: c.width, height: c.height, decoration: BoxDecoration(border: border, color: Colors.grey.shade300), child: c.props['url'] == null || c.props['url'] == '' ? const Icon(Icons.image) : Image.network(c.props['url'], fit: BoxFit.cover));
      default:
        return Container(width: c.width, height: c.height, decoration: BoxDecoration(border: border, color: Colors.white));
    }
  }

  Widget _propertiesPanel(ComponentModel c, EditorNotifier editor) {
    final type = c.type;
    final textCtrl = TextEditingController(text: c.props['text']?.toString() ?? '');
    final urlCtrl = TextEditingController(text: c.props['url']?.toString() ?? '');
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Type: $type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Text('Position', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: Text('x: ${c.left.toStringAsFixed(0)}')), Expanded(child: Text('y: ${c.top.toStringAsFixed(0)}'))]),
        const SizedBox(height: 12),
        if (type == 'button' || type == 'text') ...[
          const Text('Text'),
          const SizedBox(height: 8),
          TextField(controller: textCtrl, onChanged: (v) { final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'text': v}); editor.updateComponent(updated); setState(() {}); }, decoration: const InputDecoration(border: OutlineInputBorder())),
        ],
        if (type == 'image') ...[
          const Text('Image URL'),
          const SizedBox(height: 8),
          TextField(controller: urlCtrl, onChanged: (v) { final updated = ComponentModel(id: c.id, type: c.type, left: c.left, top: c.top, width: c.width, height: c.height, props: {...c.props, 'url': v}); editor.updateComponent(updated); setState(() {}); }, decoration: const InputDecoration(border: OutlineInputBorder())),
        ],
        const SizedBox(height: 12),
        Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () { editor.removeComponent(c.id); setState(() {}); }, icon: const Icon(Icons.delete), label: const Text('Delete'))), const SizedBox(width: 8), ElevatedButton.icon(onPressed: () { /* duplicate */ }, icon: const Icon(Icons.copy), label: const Text('Duplicate'))]),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double step = 20.0;
  final Paint paintGrid = Paint()..color = Colors.grey.withOpacity(0.06)..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
