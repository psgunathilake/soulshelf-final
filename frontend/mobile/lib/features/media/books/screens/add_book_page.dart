import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:soulshelf/data/models/book_model.dart';
import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';

class AddBookPage extends ConsumerStatefulWidget {
  const AddBookPage({super.key});

  @override
  ConsumerState<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends ConsumerState<AddBookPage> {

  final TextEditingController bookNameController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController pagesController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  int rating = 3;
  String status = "Reading";

  final List<String> statuses = ["Plan to Read", "Reading", "Completed"];

  String selectedGenre = "Fantasy";
  final List<String> genres = [
    "Fantasy",
    "Romantic",
    "Sci-Fi",
    "Horror",
    "Historical",
    "School",
  ];

  DateTime? startDate;
  DateTime? endDate;

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  File? bookCover;
  final ImagePicker _picker = ImagePicker();

  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () async {
                final file =
                await _picker.pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                Navigator.pop(context, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () async {
                final file =
                await _picker.pickImage(source: ImageSource.camera);
                if (!mounted) return;
                Navigator.pop(context, file);
              },
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        bookCover = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // GLASS HEADER
      appBar: AppBar(
        title: const Text(
          "Add Book",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [

          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/images/add_book_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),


          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 100),

                Center(
                  child: InkWell(
                    onTap: pickImage,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                        image: bookCover != null
                            ? DecorationImage(
                                image: FileImage(bookCover!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: bookCover == null
                          ? const Icon(Icons.menu_book,
                              size: 40, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Book Cover",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                textField("Book name", bookNameController),
                textField("Author", authorController),

                _label("Rating"),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: index < rating
                            ? Colors.amber
                            : Colors.grey.shade400,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),

                const SizedBox(height: 12),

                _label("Book Genre"),
                _opaqueDropdown(
                  value: selectedGenre,
                  items: genres,
                  onChanged: (v) => setState(() => selectedGenre = v),
                ),

                const SizedBox(height: 20),

                _label("Status"),
                _opaqueDropdown(
                  value: status,
                  items: statuses,
                  onChanged: (v) => setState(() => status = v),
                ),

                const SizedBox(height: 20),

                _label("Started On"),
                _datePickerField(
                  date: startDate,
                  hint: "Pick start date",
                  onTap: _pickStartDate,
                ),

                const SizedBox(height: 20),

                _label("Finished On"),
                _datePickerField(
                  date: endDate,
                  hint: "Pick end date",
                  onTap: _pickEndDate,
                ),

                const SizedBox(height: 20),

                _label("Number of Pages"),
                opaqueTextField(pagesController,
                    hint: "Enter total pages",
                    keyboardType: TextInputType.number),

                const SizedBox(height: 20),

                _label("Goodreads / Buy Link"),
                opaqueTextField(linkController,
                    hint: "https://...",
                    keyboardType: TextInputType.url),

                const SizedBox(height: 20),

                textField("Notes", notesController, maxLines: 4),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: saveBook,
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );

  Widget textField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        opaqueTextField(controller, maxLines: maxLines),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _opaqueDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _datePickerField({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? hint : formatter.format(date),
              style: TextStyle(
                fontSize: 15,
                color: date == null ? Colors.black54 : Colors.black87,
              ),
            ),
            const Icon(Icons.calendar_today,
                size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget opaqueTextField(
    TextEditingController controller, {
    int maxLines = 1,
    String hint = "",
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
      ),
    );
  }

  Future<void> saveBook() async {
    final title = bookNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book name is required')),
      );
      return;
    }

    final link = linkController.text.trim();
    if (link.isNotEmpty && !isValidUrl(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish date cannot be before start date')),
      );
      return;
    }

    final now = DateTime.now();
    final book = BookModel(
      id: const Uuid().v4(),
      title: title,
      genre: selectedGenre,
      rating: rating,
      status: _statusFromString(status),
      // coverUrl is server-driven now; uploadCover sets it after the
      // metadata POST returns a server id.
      coverUrl: null,
      reflection: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
      updatedAt: now,
      author: authorController.text.trim().isEmpty
          ? null
          : authorController.text.trim(),
      pages: int.tryParse(pagesController.text.trim()),
      link: link.isEmpty ? null : link,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final repo = ref.read(mediaRepositoryProvider);
    BookModel saved;
    try {
      saved = await repo.addBook(book);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      return;
    }

    String? coverWarning;
    if (bookCover != null) {
      if (saved.id.startsWith('local-')) {
        coverWarning =
            'Saved offline. Add cover later when you reconnect.';
      } else {
        try {
          await repo.uploadCover(
            MediaCategory.book,
            saved.id,
            bookCover!,
          );
        } catch (_) {
          coverWarning = 'Cover not uploaded — add it later from edit.';
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(coverWarning ?? 'Book saved')),
    );
    Navigator.pop(context, true);
  }

  MediaStatus _statusFromString(String s) => switch (s) {
        'Plan to Read' => MediaStatus.planned,
        'Completed' => MediaStatus.completed,
        _ => MediaStatus.ongoing,
      };
}