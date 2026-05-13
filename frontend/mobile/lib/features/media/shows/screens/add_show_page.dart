import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:ui';

import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/models/show_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';

class AddShowPage extends ConsumerStatefulWidget {
  const AddShowPage({super.key});

  @override
  ConsumerState<AddShowPage> createState() => _AddShowPageState();
}

class _AddShowPageState extends ConsumerState<AddShowPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  File? coverImage;
  String type = "TV Show";
  int rating = 0;
  String status = "Watching";
  String genre = "Drama";
  DateTime? watchedDate;
  String platform = "Netflix";
  int moodIndex = -1;

  final moods = ["😊", "😐", "😢", "🤯"];

  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        coverImage = File(picked.path);
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
          "Add Show / Film",
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

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/show_add_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.50)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // COVER IMAGE
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
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: coverImage == null
                          ? const Icon(Icons.movie_creation_outlined,
                              size: 40, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Show Cover",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // TITLE
                _label("What's the name of the show or film?"),
                _textField(
                  TextField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // TYPE
                _label("Type"),
                Row(
                  children: ["TV Show", "Movie"].map((v) {
                    return Row(
                      children: [
                        Radio<String>(
                          value: v,
                          groupValue: type,
                          onChanged: (val) => setState(() => type = val!),
                        ),
                        Text(
                          v,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // RATING
                _label("Rating"),
                Row(
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: i < rating
                            ? Colors.amber
                            : Colors.grey.shade400,
                        size: 28,
                      ),
                      onPressed: () => setState(() => rating = i + 1),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // STATUS
                _dropdown(
                  "Status",
                  status,
                  ["Plan to Watch", "Watching", "Completed"],
                  (v) => setState(() => status = v),
                ),

                // GENRE
                _dropdown(
                  "Genre",
                  genre,
                  [
                    "Action",
                    "Drama",
                    "Comedy",
                    "Romance",
                    "Thriller",
                    "Fantasy",
                    "Anime",
                    "Documentary",
                  ],
                  (v) => setState(() => genre = v),
                ),

                // DATE WATCHED
                _label("Date Watched"),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: watchedDate ?? DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => watchedDate = date);
                    }
                  },
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
                          watchedDate == null
                              ? "Pick a date"
                              : watchedDate!
                                  .toLocal()
                                  .toString()
                                  .split(" ")[0],
                          style: TextStyle(
                            fontSize: 15,
                            color: watchedDate == null
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

                // PLATFORM
                _dropdown(
                  "Platform",
                  platform,
                  ["Netflix", "Amazon Prime", "Disney+", "Cinema", "TV"],
                  (v) => setState(() => platform = v),
                ),

                // MOOD
                _label("Mood After Watching"),
                Row(
                  children: List.generate(moods.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => moodIndex = i),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: moodIndex == i
                              ? Colors.blue.shade100
                              : Colors.white.withValues(alpha: 0.6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          moods[i],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // LINK
                _label("IMDb / TMDB Link"),
                _textField(
                  TextField(
                    controller: linkController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "https://...",
                      hintStyle:
                          TextStyle(color: Colors.black38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // NOTE
                _label("My Note"),
                _textField(
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "Write your thoughts here...",
                      hintStyle:
                          TextStyle(color: Colors.black38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // SAVE
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: saveShow,
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

  // LABEL
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

  // OPAQUE TEXT FIELD CONTAINER
  Widget _textField(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Future<void> saveShow() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Show title is required')),
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
    final show = ShowModel(
      id: const Uuid().v4(),
      title: title,
      genre: genre,
      rating: rating,
      status: _statusFromUi(status),
      // Server-driven; uploadCover populates after the create POST.
      coverUrl: null,
      reflection:
          noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      endDate: watchedDate,
      createdAt: now,
      updatedAt: now,
      subType: _subTypeFromUi(type, genre),
      platform: platform,
      moodAfterWatching:
          moodIndex >= 0 && moodIndex < moods.length ? moods[moodIndex] : null,
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
    ShowModel saved;
    try {
      saved = await repo.addShow(show);
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
            MediaCategory.show,
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
      SnackBar(content: Text(coverWarning ?? 'Show saved')),
    );
    Navigator.pop(context, true);
  }

  MediaStatus _statusFromUi(String s) => switch (s) {
        'Plan to Watch' => MediaStatus.planned,
        'Completed' => MediaStatus.completed,
        _ => MediaStatus.ongoing,
      };

  ShowSubType _subTypeFromUi(String uiType, String uiGenre) {
    if (uiGenre == 'Anime') return ShowSubType.anime;
    return uiType == 'Movie' ? ShowSubType.movie : ShowSubType.tvShow;
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
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
}