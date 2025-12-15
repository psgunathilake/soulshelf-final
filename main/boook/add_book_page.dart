import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  // Controllers
  final TextEditingController bookNameController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController pagesController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  int rating = 3;
  String status = "ongoing";

  // ⭐ GENRE (DROPDOWN)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Book"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📘 Book Cover Placeholder
            Center(
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.menu_book, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text("Book Cover")),

            const SizedBox(height: 25),

            textField("Book name", bookNameController),
            textField("Author", authorController),

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
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 20),

            // 📚 Genre Dropdown (UPDATED)
            const Text("Book Genre"),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGenre,
                  isExpanded: true,
                  items: genres
                      .map(
                        (genre) => DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGenre = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📅 Start Reading Date
            const Text("Start Reading Date"),
            const SizedBox(height: 5),
            datePickerField(
              text: startDate == null
                  ? "Select start date"
                  : formatter.format(startDate!),
              onTap: () => pickDate(isStart: true),
            ),

            const SizedBox(height: 15),

            // 📅 End Reading Date
            const Text("End Reading Date"),
            const SizedBox(height: 5),
            datePickerField(
              text: endDate == null
                  ? "Select end date"
                  : formatter.format(endDate!),
              onTap: () => pickDate(isStart: false),
            ),

            const SizedBox(height: 20),

            // 📌 Book Status
            const Text("Book status"),
            Wrap(
              spacing: 10,
              children: ["ongoing", "hold", "complete", "drop"]
                  .map((s) => ChoiceChip(
                label: Text(s),
                selected: status == s,
                onSelected: (_) {
                  setState(() {
                    status = s;
                  });
                },
              ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // 🔢 Number of Pages (numbers only)
            const Text("Number of Pages"),
            const SizedBox(height: 5),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: inputDecoration("Enter total pages"),
            ),

            const SizedBox(height: 20),

            // 📝 Notes
            textField("Notes", notesController, maxLines: 4),

            const SizedBox(height: 30),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveBook,
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Text Field
  Widget textField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: inputDecoration(""),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // 🔹 Input Decoration
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // 🔹 Date Picker Field
  Widget datePickerField({
    required String text,
    required VoidCallback onTap,
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

  // 🔹 SAVE BOOK (INCLUDES GENRE)
  void saveBook() {
    if (bookNameController.text.isEmpty ||
        authorController.text.isEmpty) {
      return;
    }

    final bookData = {
      "name": bookNameController.text,
      "author": authorController.text,
      "rating": rating,
      "genre": selectedGenre,
      "status": status,
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
      "pages": pagesController.text,
      "notes": notesController.text,
    };

    Navigator.pop(context, bookData);
  }
}
