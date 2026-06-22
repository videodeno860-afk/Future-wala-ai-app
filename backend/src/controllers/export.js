const express = require('express');
const router = express.Router();
const archiver = require('archiver');
const fs = require('fs');
const path = require('path');

// Create a zip from posted project JSON and return as attachment
router.post('/export/zip', async (req, res) => {
  try {
    const project = req.body.project;
    if (!project) return res.status(400).json({ error: 'Missing project payload' });

    const tmpDir = path.join('/tmp', `proj_${Date.now()}`);
    fs.mkdirSync(tmpDir, { recursive: true });

    // Create a minimal Flutter project structure and multi-screen main.dart
    const libDir = path.join(tmpDir, 'lib');
    fs.mkdirSync(libDir, { recursive: true });

    // Generate routes and widgets per screen
    const screens = project.screens || [];
    let imports = `import 'package:flutter/material.dart';\n`;
    let routesDecl = '';
    let routesMap = '';
    let widgetsCode = '';

    for (let i = 0; i < screens.length; i++) {
      const s = screens[i];
      const widgetName = `Screen${i + 1}`;
      routesDecl += `static const route${i} = '/screen_${i}';\n`;

      // Build widget body from components
      let children = '';
      const comps = s.components || [];
      for (let j = 0; j < comps.length; j++) {
        const c = comps[j];
        if (c.type === 'text') {
          const txt = (c.props && c.props.text) ? c.props.text.replace(/`/g, "'") : 'Text';
          children += `Text('${txt}'),\n`;
        } else if (c.type === 'button') {
          const txt = (c.props && c.props.text) ? c.props.text.replace(/`/g, "'") : 'Button';
          children += `ElevatedButton(onPressed: () {}, child: Text('${txt}')),\n`;
        } else if (c.type === 'image') {
          const url = (c.props && c.props.url) ? c.props.url : '';
          if (url) {
            children += `Image.network('${url}'),\n`;
          } else {
            children += `Container(width: 100, height: 80, color: Colors.grey),\n`;
          }
        }
      }

      widgetsCode += `class ${widgetName} extends StatelessWidget { const ${widgetName}({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('${s.name || 'Screen'}')), body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [${children}])),),); }}\n\n`;
      routesMap += `'/screen_${i}': (context) => const ${widgetName}(),\n`;
    }

    const mainDart = `${imports}

void main() => runApp(const ExportedApp());

class ExportedApp extends StatelessWidget {
  const ExportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${project.title || 'Exported App'}',
      initialRoute: '/screen_0',
      routes: {
        ${routesMap}
      },
    );
  }
}

${widgetsCode}
`;

    fs.writeFileSync(path.join(libDir, 'main.dart'), mainDart);

    // Create pubspec minimal
    const pubspec = `name: exported_app\ndescription: Exported from Future AI builder\nversion: 1.0.0\nenvironment:\n  sdk: ">=2.18.0 <3.0.0"\ndependencies:\n  flutter:\n    sdk: flutter\n  cupertino_icons: ^1.0.2\n`;
    fs.writeFileSync(path.join(tmpDir, 'pubspec.yaml'), pubspec);

    const zipPath = path.join('/tmp', `export_${Date.now()}.zip`);
    const output = fs.createWriteStream(zipPath);
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', function () {
      res.download(zipPath, `${project.title || 'project'}.zip`, (err) => {
        try { fs.unlinkSync(zipPath); } catch (e) {}
      });
    });

    archive.pipe(output);
    archive.directory(tmpDir, false);
    await archive.finalize();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
