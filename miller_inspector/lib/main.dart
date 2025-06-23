import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MillerInspectorApp());
}

class MillerInspectorApp extends StatelessWidget {
  const MillerInspectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miller Inspector',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF003366),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF003366),
          secondary: Color(0xFF006699),
        ),
      ),
      home: const ReportFormPage(),
    );
  }
}

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({Key? key}) : super(key: key);

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _inspectorController = TextEditingController(text: 'Gustavo Diaz');
  final _workerController = TextEditingController();
  final _processController = TextEditingController();
  final _pieceController = TextEditingController();
  XFile? _photo;

  Future<void> _takePhoto() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _photo = photo;
      });
    }
  }

  Future<File> _generatePdf() async {
    final pdf = pw.Document();
    final image = _photo != null ? pw.MemoryImage(await _photo!.readAsBytes()) : null;

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Informe de Inspección', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Text('Inspector: ${_inspectorController.text}'),
              pw.Text('Operario: ${_workerController.text}'),
              pw.Text('Proceso / Máquina: ${_processController.text}'),
              pw.Text('Pieza: ${_pieceController.text}'),
              if (image != null)
                pw.Padding(padding: const pw.EdgeInsets.only(top: 16), child: pw.Image(image)),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'informe.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _shareReport() async {
    final storage = await Permission.storage.request();
    if (!storage.isGranted) return;

    final file = await _generatePdf();
    await Share.shareXFiles([XFile(file.path)], text: 'Informe de Inspección');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Informe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _inspectorController,
              decoration: const InputDecoration(labelText: 'Inspector'),
            ),
            TextField(
              controller: _workerController,
              decoration: const InputDecoration(labelText: 'Operario inspeccionado'),
            ),
            TextField(
              controller: _processController,
              decoration: const InputDecoration(labelText: 'Proceso / Máquina'),
            ),
            TextField(
              controller: _pieceController,
              decoration: const InputDecoration(labelText: 'Pieza'),
            ),
            const SizedBox(height: 16),
            if (_photo != null)
              Image.file(File(_photo!.path), height: 200),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _shareReport,
              icon: const Icon(Icons.share),
              label: const Text('Generar y Compartir PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
