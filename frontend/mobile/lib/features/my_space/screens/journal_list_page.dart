import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class JournalListPage extends StatefulWidget {
  final DateTime date;
  final List<dynamic>? documentJson; // ✅ Accept JSON

  const JournalListPage({
    super.key,
    required this.date,
    this.documentJson,
  });

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  late QuillController quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _showToolbar = false;

  @override
  void initState() {
    super.initState();

    // Document.fromJson throws "Document Delta cannot be empty" on []
    // and also rejects Deltas that don't end with a trailing newline op.
    // Guard against empty list, and fall back to a fresh basic controller
    // if the persisted Delta is malformed for any reason — we don't want
    // a stale Hive payload to crash the journal screen.
    final json = widget.documentJson;
    if (json != null && json.isNotEmpty) {
      try {
        quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        quillController = QuillController.basic();
      }
    } else {
      quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Insert Image Safely
  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    _focusNode.requestFocus();

    final bytes = await File(pickedFile.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    final imageUrl = 'data:image/png;base64,$base64Image';

    int index = quillController.selection.baseOffset;
    if (index < 0) {
      index = quillController.document.length;
    }

    quillController.document.insert(
      index,
      BlockEmbed.image(imageUrl),
    );

    quillController.document.insert(index + 1, '\n');

    quillController.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat("EEEE, MMM d, yyyy").format(widget.date);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Journal Note"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/journal_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Transparent Editor
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QuillEditor(
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        controller: quillController,
                        config: QuillEditorConfig(
                          expands: true,
                          padding: const EdgeInsets.all(18),
                          embedBuilders: [
                            CustomImageBuilder(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Hidden Toolbar
                if (_showToolbar)
                  Container(
                    color: Colors.white.withValues(alpha: 0.95),
                    child: QuillSimpleToolbar(
                      controller: quillController,
                      config: const QuillSimpleToolbarConfig(
                        multiRowsDisplay: false,
                        showAlignmentButtons: false,
                        showBackgroundColorButton: false,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Attach Image"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showToolbar = !_showToolbar;
                            });
                          },
                          icon: const Icon(Icons.format_size),
                          label: const Text("Format"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Save Button (Return JSON)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final json =
                        quillController.document.toDelta().toJson();
                        Navigator.pop(context, json);
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Small Image with Delete
class CustomImageBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final controller = embedContext.controller;
    final node = embedContext.node;
    final readOnly = embedContext.readOnly;
    final String imageUrl = node.value.data;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Stack(
          children: [
            Container(
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(imageUrl.split(',').last),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (!readOnly)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    final delta = controller.document.toDelta();
                    int offset = 0;

                    for (final op in delta.toList()) {
                      if (op.data is Map) {
                        final data = op.data as Map;
                        if (data.containsKey('image') &&
                            data['image'] == imageUrl) {
                          controller.document.delete(offset, 1);
                          break;
                        }
                      }
                      offset += op.length ?? 0;
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}