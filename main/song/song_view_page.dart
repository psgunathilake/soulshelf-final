import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SongViewPage extends StatefulWidget {
  final Map<String, dynamic> song;

  const SongViewPage({super.key, required this.song});

  @override
  State<SongViewPage> createState() => _SongViewPageState();
}

class _SongViewPageState extends State<SongViewPage> {
  late TextEditingController title;
  late TextEditingController singer;
  late TextEditingController composer;
  late TextEditingController lyricist;
  late TextEditingController lyrics;
  late TextEditingController link;
  late TextEditingController notes;

  int rating = 0;
  bool favorite = false;
  bool isEditing = false;

  String genre = "Pop";
  String language = "English";
  String mood = "Happy";

  DateTime? releaseDate;
  final DateFormat formatter = DateFormat("yyyy-MM-dd");

  final genres = [
    "Pop",
    "Rock",
    "Hip-Hop",
    "Classical",
    "Jazz",
    "Lo-Fi",
    "Romantic",
    "EDM"
  ];

  final languages = ["English", "Sinhala", "Tamil", "Korean", "Hindi"];
  final moods = ["Happy", "Sad", "Chill", "Energetic", "Romantic", "Motivational"];

  @override
  void initState() {
    super.initState();

    title = TextEditingController(text: widget.song["title"] ?? "");
    singer = TextEditingController(text: widget.song["singer"] ?? "");
    composer = TextEditingController(text: widget.song["composer"] ?? "");
    lyricist = TextEditingController(text: widget.song["lyricist"] ?? "");
    lyrics = TextEditingController(text: widget.song["lyrics"] ?? "");
    link = TextEditingController(text: widget.song["link"] ?? "");
    notes = TextEditingController(text: widget.song["notes"] ?? "");

    rating = widget.song["rating"] ?? 0;
    favorite = widget.song["favorite"] ?? false;

    genre = widget.song["genre"] ?? "Pop";
    language = widget.song["language"] ?? "English";
    mood = widget.song["mood"] ?? "Happy";

    releaseDate = widget.song["releaseDate"] != null
        ? DateTime.parse(widget.song["releaseDate"])
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text("Song Details"),
        backgroundColor: const Color(0xFFB5D6F6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🎵 Cover Image
            Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                image: widget.song["imagePath"] != null
                    ? DecorationImage(
                  image: FileImage(File(widget.song["imagePath"])),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.song["imagePath"] == null
                  ? const Icon(Icons.music_note, size: 60)
                  : null,
            ),

            const SizedBox(height: 24),

            field("Song Title", title),
            field("Singer / Artist", singer),
            field("Composer / Music Director", composer),
            field("Lyricist / Writer", lyricist),

            const SizedBox(height: 10),

            const Text("Rating"),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed:
                  isEditing ? () => setState(() => rating = i + 1) : null,
                );
              }),
            ),

            dropdown("Genre", genre, genres,
                    (v) => isEditing ? setState(() => genre = v!) : null),
            dropdown("Language", language, languages,
                    (v) => isEditing ? setState(() => language = v!) : null),
            dropdown("Mood / Vibe", mood, moods,
                    (v) => isEditing ? setState(() => mood = v!) : null),

            const SizedBox(height: 10),

            Text(
              "Release Date: ${releaseDate == null ? "Not set" : formatter.format(releaseDate!)}",
            ),

            field("Lyrics", lyrics, maxLines: 5),
            field("YouTube / Spotify Link", link),
            field("Personal Notes", notes, maxLines: 3),

            SwitchListTile(
              title: const Text("Favorite ❤️"),
              value: favorite,
              onChanged:
              isEditing ? (v) => setState(() => favorite = v) : null,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (isEditing) {
                  Navigator.pop(context, {
                    ...widget.song,
                    "title": title.text,
                    "singer": singer.text,
                    "composer": composer.text,
                    "lyricist": lyricist.text,
                    "rating": rating,
                    "genre": genre,
                    "language": language,
                    "mood": mood,
                    "lyrics": lyrics.text,
                    "favorite": favorite,
                    "link": link.text,
                    "notes": notes.text,
                    "releaseDate":
                    releaseDate?.toIso8601String(),
                  });
                } else {
                  setState(() => isEditing = true);
                }
              },
              child: Text(isEditing ? "Save" : "Edit"),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextField(
            controller: controller,
            enabled: isEditing,
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget dropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: isEditing ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
