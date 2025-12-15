import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final picker = ImagePicker();
  File? coverImage;

  final titleController = TextEditingController();
  final singerController = TextEditingController();
  final composerController = TextEditingController();
  final lyricistController = TextEditingController();
  final lyricsController = TextEditingController();
  final linkController = TextEditingController();
  final notesController = TextEditingController();

  int rating = 3;
  bool favorite = false;

  String genre = "Pop";
  String language = "English";
  String mood = "Happy";

  DateTime? releaseDate;
  final formatter = DateFormat("yyyy-MM-dd");

  final genres = [
    "Pop", "Rock", "Hip-Hop", "Classical",
    "Jazz", "Lo-Fi", "Romantic", "EDM"
  ];

  final languages = ["English", "Sinhala", "Tamil", "Korean", "Hindi"];
  final moods = ["Happy", "Sad", "Chill", "Energetic", "Romantic", "Motivational"];

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => coverImage = File(picked.path));
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => releaseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Song")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                    image: coverImage != null
                        ? DecorationImage(
                        image: FileImage(coverImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: coverImage == null
                      ? const Icon(Icons.music_note, size: 40)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            field("Song Title", titleController),
            field("Singer / Artist", singerController),
            field("Composer / Music Director", composerController),
            field("Lyricist / Writer", lyricistController),

            const Text("Rating"),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => rating = i + 1),
              )),
            ),

            dropdown("Song Genre", genre, genres, (v) => setState(() => genre = v)),
            dropdown("Language", language, languages, (v) => setState(() => language = v)),
            dropdown("Mood / Vibe", mood, moods, (v) => setState(() => mood = v)),

            const SizedBox(height: 10),

            InkWell(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(releaseDate == null
                        ? "Select Release Date"
                        : formatter.format(releaseDate!)),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            field("Lyrics", lyricsController, maxLines: 5),

            SwitchListTile(
              title: const Text("Mark as Favorite"),
              value: favorite,
              onChanged: (v) => setState(() => favorite = v),
            ),

            field("YouTube / Spotify Link", linkController),
            field("Personal Notes", notesController, maxLines: 3),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveSong,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String label, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget dropdown(String label, String value, List<String> items,
      Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  void saveSong() {
    Navigator.pop(context, {
      "title": titleController.text,
      "singer": singerController.text,
      "composer": composerController.text,
      "lyricist": lyricistController.text,
      "rating": rating,
      "lyrics": lyricsController.text,
      "genre": genre,
      "language": language,
      "mood": mood,
      "favorite": favorite,
      "link": linkController.text,
      "notes": notesController.text,
      "releaseDate": releaseDate?.toIso8601String(),
      "imagePath": coverImage?.path,
    });
  }
}
