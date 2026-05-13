import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/models/song_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';

class AddSongPage extends ConsumerStatefulWidget {
  const AddSongPage({super.key});

  @override
  ConsumerState<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends ConsumerState<AddSongPage> {
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
  String status = "Listening";

  DateTime? releaseDate;
  final formatter = DateFormat("yyyy-MM-dd");

  final genres = [
    "Pop","Rock","Hip-Hop","Classical",
    "Jazz","Lo-Fi","Romantic","EDM"
  ];

  final languages = ["English","Sinhala","Tamil","Korean","Hindi"];
  final moods = ["Happy","Sad","Chill","Energetic","Romantic","Motivational"];
  final statuses = ["Plan to Listen", "Listening", "Completed"];

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

  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// GLASS HEADER
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Add Song",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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

      /// BACKGROUND IMAGE
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/music_add_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.55)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Cover Image
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                        image: coverImage != null
                            ? DecorationImage(
                                image: FileImage(coverImage!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: coverImage == null
                          ? const Icon(Icons.music_note,
                              size: 40, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Song Cover",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                field("Song Title", titleController),
                field("Singer / Artist", singerController),
                field("Composer / Music Director", composerController),
                field("Lyricist / Writer", lyricistController),

                _label("Rating"),
                Row(
                  children: List.generate(
                      5,
                      (i) => IconButton(
                            icon: Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: i < rating
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                              size: 28,
                            ),
                            onPressed: () => setState(() => rating = i + 1),
                          )),
                ),

                const SizedBox(height: 12),

                dropdown("Song Genre", genre, genres,
                    (v) => setState(() => genre = v)),
                dropdown("Language", language, languages,
                    (v) => setState(() => language = v)),
                dropdown("Mood / Vibe", mood, moods,
                    (v) => setState(() => mood = v)),
                dropdown("Status", status, statuses,
                    (v) => setState(() => status = v)),

                _label("Release Date"),
                InkWell(
                  onTap: pickDate,
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
                          releaseDate == null
                              ? "Select release date"
                              : formatter.format(releaseDate!),
                          style: TextStyle(
                            fontSize: 15,
                            color: releaseDate == null
                                ? Colors.black54
                                : Colors.black87,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                field("Lyrics", lyricsController, maxLines: 5),

                _label("YouTube / Spotify Link"),
                TextField(
                  controller: linkController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText:
                        "https://youtube.com/... or https://spotify.com/...",
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.link, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.92),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.black12, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                field("Personal Notes", notesController, maxLines: 3),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "Mark as Favorite",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    value: favorite,
                    onChanged: (v) => setState(() => favorite = v),
                  ),
                ),

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
                    onPressed: saveSong,
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

  /// TEXT FIELD
  Widget field(String label, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// DROPDOWN
  Widget dropdown(
      String label, String value, List<String> items, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
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
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> saveSong() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song title is required')),
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

    final now = DateTime.now();
    final song = SongModel(
      id: const Uuid().v4(),
      title: title,
      genre: genre,
      rating: rating,
      status: _statusFromUi(status),
      // Server-driven; uploadCover populates after the create POST.
      coverUrl: null,
      reflection: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
      singer: _nonEmpty(singerController.text),
      composer: _nonEmpty(composerController.text),
      lyricist: _nonEmpty(lyricistController.text),
      lyrics: _nonEmpty(lyricsController.text),
      link: link.isEmpty ? null : link,
      language: language,
      mood: mood,
      releaseDate: releaseDate,
      favorite: favorite,
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
    SongModel saved;
    try {
      saved = await repo.addSong(song);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      return;
    }

    String? coverWarning;
    if (coverImage != null) {
      if (saved.id.startsWith('local-')) {
        coverWarning =
            'Saved offline. Add cover later when you reconnect.';
      } else {
        try {
          await repo.uploadCover(
            MediaCategory.song,
            saved.id,
            coverImage!,
          );
        } catch (_) {
          coverWarning = 'Cover not uploaded — add it later from edit.';
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(coverWarning ?? 'Song saved')),
    );
    Navigator.pop(context, true);
  }

  String? _nonEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  MediaStatus _statusFromUi(String s) => switch (s) {
        'Plan to Listen' => MediaStatus.planned,
        'Completed' => MediaStatus.completed,
        _ => MediaStatus.ongoing,
      };
}