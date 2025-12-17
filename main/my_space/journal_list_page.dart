import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';

class JournalListPage extends StatefulWidget {
  final DateTime date;
  final String existingText; // ✅ REQUIRED

  const JournalListPage({
    super.key,
    required this.date,
    required this.existingText,
  });

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  late QuillController quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load existing text if available
    quillController = widget.existingText.isNotEmpty
        ? QuillController(
      document: Document()..insert(0, widget.existingText),
      selection: const TextSelection.collapsed(offset: 0),
    )
        : QuillController.basic();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat("EEEE, MMM d, yyyy").format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Write Journal"),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              formattedDate,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          // EDITOR
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuillEditor(
                focusNode: _focusNode,
                scrollController: _scrollController,
                configurations: QuillEditorConfigurations(
                  controller: quillController,
                  expands: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // TOOLBAR
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: quillController,
            ),
          ),

          // SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    quillController.document.toPlainText(),
                  );
                },
                child: const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
