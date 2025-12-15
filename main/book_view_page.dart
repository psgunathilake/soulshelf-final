import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookViewPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookViewPage({super.key, required this.book});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage> {
  late TextEditingController nameController;
  late TextEditingController authorController;
  late TextEditingController pagesController;
  late TextEditingController notesController;

  late int rating;
  late String status;

  DateTime? startDate;
  DateTime? endDate;

  bool isEditing = false;

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.book["name"]);
    authorController = TextEditingController(text: widget.book["author"]);
    pagesController =
        TextEditingController(text: widget.book["pages"] ?? "");
    notesController =
        TextEditingController(text: widget.book["notes"] ?? "");

    rating = widget.book["rating"];
    status = widget.book["status"] ?? "ongoing";

    startDate = widget.book["startDate"] != null
        ? DateTime.parse(widget.book["startDate"])
        : null;

    endDate = widget.book["endDate"] != null
        ? DateTime.parse(widget.book["endDate"])
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildField("Book Name", nameController),
            buildField("Author", authorController),

            const SizedBox(height: 15),

            // ⭐ Rating
            const Text("Rating"),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: isEditing
                      ? () => setState(() => rating = index + 1)
                      : null,
                );
              }),
            ),

            const SizedBox(height: 15),

            // 📅 Start Date
            const Text("Start Reading Date"),
            const SizedBox(height: 5),
            dateField(
              text: startDate == null
                  ? "Not selected"
                  : formatter.format(startDate!),
              onTap: isEditing ? () => pickDate(isStart: true) : null,
            ),

            const SizedBox(height: 15),

            // 📅 End Date
            const Text("End Reading Date"),
            const SizedBox(height: 5),
            dateField(
              text: endDate == null
                  ? "Not selected"
                  : formatter.format(endDate!),
              onTap: isEditing ? () => pickDate(isStart: false) : null,
            ),

            const SizedBox(height: 15),

            // 📌 Status
            const Text("Book Status"),
            Wrap(
              spacing: 10,
              children: ["ongoing", "hold", "complete", "drop"]
                  .map(
                    (s) => ChoiceChip(
                  label: Text(s),
                  selected: status == s,
                  onSelected:
                  isEditing ? (_) => setState(() => status = s) : null,
                ),
              )
                  .toList(),
            ),

            const SizedBox(height: 15),

            buildField("Number of Pages", pagesController,
                keyboard: TextInputType.number),
            buildField("Notes", notesController, maxLines: 4),

            const SizedBox(height: 30),

            // ✏️ EDIT / 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (isEditing) {
                    saveUpdatedBook();
                  } else {
                    setState(() => isEditing = true);
                  }
                },
                child: Text(isEditing ? "Save" : "Edit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Text Field Builder
  Widget buildField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          enabled: isEditing,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // 🔹 Date Display Field
  Widget dateField({
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  // 🔹 Pick Date
  Future<void> pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // 🔹 Save Updated Book
  void saveUpdatedBook() {
    Navigator.pop(context, {
      "name": nameController.text,
      "author": authorController.text,
      "rating": rating,
      "status": status,
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
      "pages": pagesController.text,
      "notes": notesController.text,
    });
  }
}
