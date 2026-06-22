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

    // Create a minimal Flutter main.dart for the exported project
    const libDir = path.join(tmpDir, 'lib');
    fs.mkdirSync(libDir, { recursive: true });

    const mainDart = `import 'package:flutter/material.dart';\nvoid main() => runApp(const MyApp());\nclass MyApp extends StatelessWidget { const MyApp({super.key}); @override Widget build(BuildContext context){ return MaterialApp(home: Scaffold(body: Center(child: Text('Exported app: ${project.title || 'Untitled'}')))); } }`;
    fs.writeFileSync(path.join(libDir, 'main.dart'), mainDart);

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
