import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/features/collections/widgets/add_to_collection_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class SongViewPage extends StatefulWidget {
  final Map<String, dynamic> song;

  const SongViewPage({super.key, required this.song});

  @override
  State<SongViewPage> createState() => _SongViewPageState();
}

class _SongViewPageState extends State<SongViewPage>
    with SingleTickerProviderStateMixin {

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

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final genres = [
    "Pop","Rock","Hip-Hop","Classical",
    "Jazz","Lo-Fi","Romantic","EDM"
  ];

  final languages = ["English", "Sinhala", "Tamil", "Korean", "Hindi"];

  final moods = [
    "Happy","Sad","Chill",
    "Energetic","Romantic","Motivational"
  ];

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);
    final success = await launchUrl(uri,
        mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text("Song Details"),
        backgroundColor: const Color(0xFFB5D6F6),
        elevation: 0,

        //DELETE BUTTON
        actions: [
          if (!isEditing && widget.song['id'] != null)
            IconButton(
              tooltip: 'Add to collection',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => showAddToCollectionSheet(
                context, mediaId: widget.song['id'] as String),
            ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSong,
            ),
        ],
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        backgroundColor: const Color(0xFF6CAEEB),
        child: const Icon(Icons.edit),
        onPressed: () => setState(() => isEditing = true),
      ),

      //BACKGROUND IMAGE
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/song_view_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: isEditing ? buildEditMode() : buildViewMode(),
          ),
        ],
      ),
    );
  }

  //DELETE SONG

  void deleteSong() async {

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Song"),
          content: const Text(
              "Are you sure you want to delete this song?"
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),

          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmDelete == true) {
      Navigator.pop(context, {"delete": true});
    }
  }

  //VIEW MODE

  Widget buildViewMode() {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  image: coverImageProvider(widget.song["imagePath"] as String?) != null
                      ? DecorationImage(
                    image: coverImageProvider(widget.song["imagePath"] as String?)!,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: coverImageProvider(widget.song["imagePath"] as String?) == null
                    ? const Icon(Icons.music_note, size: 60)
                    : null,
              ),

              const SizedBox(height: 25),

              Text(
                title.text,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                singer.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 10),

              if (composer.text.isNotEmpty)
                Text("🎼 Composer: ${composer.text}",
                    style: const TextStyle(fontSize: 14)),

              if (lyricist.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("✍️ Lyricist: ${lyricist.text}",
                      style: const TextStyle(fontSize: 14)),
                ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 26,
                  );
                }),
              ),

              const SizedBox(height: 15),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  blueChip("🎧 $genre"),
                  blueChip("🌍 $language"),
                  blueChip("✨ $mood"),
                ],
              ),

              const SizedBox(height: 20),

              if (releaseDate != null)
                Text("📅 ${formatter.format(releaseDate!)}"),

              if (favorite)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text("❤️ Marked as Favorite",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),

              const SizedBox(height: 20),

              if (lyrics.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📜 Lyrics",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lyrics.text,
                        style: const TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),

              if (link.text.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6CAEEB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Open in YouTube / Spotify"),
                  onPressed: () => openLink(link.text),
                ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  notes.text.isEmpty
                      ? "No personal notes added..."
                      : notes.text,
                  style: const TextStyle(height: 1.5),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget blueChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD6E9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text),
    );
  }

  //EDIT MODE

  Widget buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          field("Song Title", title),
          field("Singer / Artist", singer),
          field("Composer", composer),
          field("Lyricist", lyricist),

          const SizedBox(height: 10),

          const Text("Rating"),
          Row(
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => rating = i + 1),
              );
            }),
          ),

          dropdown("Genre", genre, genres,
                  (v) => setState(() => genre = v!)),
          dropdown("Language", language, languages,
                  (v) => setState(() => language = v!)),
          dropdown("Mood", mood, moods,
                  (v) => setState(() => mood = v!)),

          field("Lyrics", lyrics, maxLines: 5),
          field("Link", link),
          field("Notes", notes, maxLines: 3),

          SwitchListTile(
            title: const Text("Favorite ❤️"),
            value: favorite,
            onChanged: (v) => setState(() => favorite = v),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
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
                "releaseDate": releaseDate?.toIso8601String(),
              });
            },
            child: const Text("Save"),
          ),
        ],
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}