
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TextCanvasApp());
}

class TextCanvasApp extends StatelessWidget {
  const TextCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Text Canvas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const TextCanvasScreen(),
    );
  }
}

class TextItem {
  final String id;
  String text;
  String font;
  Offset position;
  double fontSize;
  bool isItalic;

  TextItem({
    required this.id,
    required this.text,
    required this.font,
    required this.position,
    this.fontSize = 32,
    this.isItalic = false,
  });

  TextItem copy() => TextItem(
        id: id,
        text: text,
        font: font,
        position: position,
        fontSize: fontSize,
        isItalic: isItalic,
      );
}

class TextCanvasScreen extends StatefulWidget {
  const TextCanvasScreen({super.key});

  @override
  _TextCanvasScreenState createState() => _TextCanvasScreenState();
}

class _TextCanvasScreenState extends State<TextCanvasScreen> {
  final List<TextItem> _items = [];
  final GlobalKey _canvasKey = GlobalKey();

  // Undo/Redo stacks
  final List<List<TextItem>> _undoStack = [];
  final List<List<TextItem>> _redoStack = [];

  //set of fonts
  final List<String> _fonts = [
    'Lato',
    'Roboto',
    'Oswald',
    'Merriweather',
    'Pacifico',
  ];

  void _pushUndo() {
    _undoStack.add(_items.map((e) => e.copy()).toList());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_items.map((e) => e.copy()).toList());
    final snapshot = _undoStack.removeLast();
    setState(() {
      _items
        ..clear()
        ..addAll(snapshot.map((e) => e.copy()));
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_items.map((e) => e.copy()).toList());
    final snapshot = _redoStack.removeLast();
    setState(() {
      _items
        ..clear()
        ..addAll(snapshot.map((e) => e.copy()));
    });
  }

  TextStyle _styleForFont(String font, double size, {bool isItalic = false}) {
    TextStyle baseStyle;
    switch (font) {
      case 'Oswald':
        baseStyle = GoogleFonts.oswald(fontSize: size);
        break;
      case 'Merriweather':
        baseStyle = GoogleFonts.merriweather(fontSize: size);
        break;
      case 'Pacifico':
        baseStyle = GoogleFonts.pacifico(fontSize: size);
        break;
      case 'Lato':
        baseStyle = GoogleFonts.lato(fontSize: size);
        break;
      case 'Roboto':
      default:
        baseStyle = GoogleFonts.roboto(fontSize: size);
        break;
    }
    return baseStyle.copyWith(
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );
  }

  Future<void> _showPreview() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(pngBytes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }
  void _addTextDialog() async {
    final textController = TextEditingController();
    String selectedFont = _fonts.first;
    double fontSize = 32;
    bool isItalic = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, localSetState) {
          //values which are non-null are not accepted 
          selectedFont = selectedFont;
          fontSize = fontSize;
          isItalic = isItalic;
          return AlertDialog(
            title: const Text('Add Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Text'),
                    onChanged: (_) => localSetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Font:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedFont,
                        items: _fonts
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            localSetState(() {
                              selectedFont = v;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Size:'),
                      Expanded(
                        child: Slider(
                          min: 12,
                          max: 120,
                          value: fontSize,
                          onChanged: (v) {
                            localSetState(() {
                              fontSize = v;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Italic'),
                      Switch(
                        value: isItalic,
                        onChanged: (v) {
                          localSetState(() {
                            isItalic = v;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      textController.text.isEmpty ? 'Sample Text' : textController.text,
                      style: _styleForFont(selectedFont, fontSize, isItalic: isItalic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return; // require non-empty text
                  _pushUndo();
                  final newItem = TextItem(
                    id: UniqueKey().toString(),
                    text: text,
                    font: selectedFont,
                    position: const Offset(24, 40), // initial position inside box
                    fontSize: fontSize,
                    isItalic: isItalic,
                  );
                  setState(() => _items.add(newItem));
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
  void _editItemDialog(TextItem item) async {
    final textController = TextEditingController(text: item.text);
    String selectedFont = item.font;
    double fontSize = item.fontSize;
    bool isItalic = item.isItalic;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, localSetState) {
          return AlertDialog(
            title: const Text('Edit Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Text'),
                    onChanged: (_) => localSetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Font:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedFont,
                        items: _fonts
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) localSetState(() => selectedFont = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Size:'),
                      Expanded(
                        child: Slider(
                          min: 12,
                          max: 120,
                          value: fontSize,
                          onChanged: (v) {
                            localSetState(() {
                              fontSize = v;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Italic'),
                      Switch(
                        value: isItalic,
                        onChanged: (v) => localSetState(() => isItalic = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      textController.text.isEmpty ? 'Sample Text' : textController.text,
                      style: _styleForFont(selectedFont, fontSize, isItalic: isItalic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  _pushUndo();
                  setState(() {
                    item.text = textController.text;
                    item.font = selectedFont;
                    item.fontSize = fontSize;
                    item.isItalic = isItalic;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Canvas'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
          IconButton(onPressed: _redo, icon: const Icon(Icons.redo)),
          // Preview optional was not mentioned in the assignment but is useful
          IconButton(onPressed: _showPreview, icon: const Icon(Icons.preview)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: LayoutBuilder(builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight;

                          return Stack(
                            children: [
                              Positioned.fill(child: Container(color: Colors.white)),
                              ..._items.map((item) {
                                return _buildTextWidget(item, maxW, maxH);
                              }),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: ElevatedButton(
                onPressed: _addTextDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: const Color(0xFF4489F9),
                  elevation: 6,
                ),
                child: const Text(
                  'Add Text',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWidget(TextItem item, double maxW, double maxH) {
    // for italics
    final textPainter = TextPainter(
      text: TextSpan(text: item.text, style: _styleForFont(item.font, item.fontSize, isItalic: item.isItalic)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 10,
    )..layout(maxWidth: maxW);

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // ensure initial item.position is clamped (if someone loaded or restored)
    final clampedInitialDx = item.position.dx.clamp(0.0, (maxW - textWidth).clamp(0.0, maxW));
    final clampedInitialDy = item.position.dy.clamp(0.0, (maxH - textHeight).clamp(0.0, maxH));
    item.position = Offset(clampedInitialDx, clampedInitialDy);

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () => _editItemDialog(item),
        onPanStart: (_) => _pushUndo(),
        onPanUpdate: (details) {
          setState(() {
            final newPos = item.position + details.delta;
            final clampedX = newPos.dx.clamp(0.0, (maxW - textWidth).clamp(0.0, maxW));
            final clampedY = newPos.dy.clamp(0.0, (maxH - textHeight).clamp(0.0, maxH));
            item.position = Offset(clampedX, clampedY);
          });
        },
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            item.text,
            style: _styleForFont(item.font, item.fontSize, isItalic: item.isItalic).copyWith(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
