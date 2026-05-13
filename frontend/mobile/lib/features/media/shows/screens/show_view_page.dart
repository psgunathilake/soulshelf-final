import 'package:flutter/material.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/features/collections/widgets/add_to_collection_sheet.dart';

class ShowViewPage extends StatefulWidget {
  final Map<String, dynamic> show;

  const ShowViewPage({super.key, required this.show});

  @override
  State<ShowViewPage> createState() => _ShowViewPageState();
}

class _ShowViewPageState extends State<ShowViewPage> {
  late TextEditingController title;
  late TextEditingController genre;
  late TextEditingController status;
  late TextEditingController seasons;
  late TextEditingController reflection;

  int rating = 0;
  bool isEditing = false;

  String? imagePath;

  @override
  void initState() {
    super.initState();

    title = TextEditingController(text: widget.show["title"] ?? "");
    genre = TextEditingController(text: widget.show["genre"] ?? "");
    status = TextEditingController(text: widget.show["status"] ?? "");
    seasons = TextEditingController(
        text: widget.show["seasons"]?.toString() ?? "");
    reflection =
        TextEditingController(text: widget.show["reflection"] ?? "");

    rating = widget.show["rating"] ?? 0;
    imagePath = widget.show["image"] as String?;
  }

  // 🗑 DELETE FUNCTION
  void deleteShow() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Show"),
          content:
          const Text("Are you sure you want to delete this show?"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), //light grey

      appBar: AppBar(
        title: const Text("Show Details"),
        backgroundColor: Colors.white,
        elevation: 0,

        actions: [
          if (!isEditing && widget.show['id'] != null)
            IconButton(
              tooltip: 'Add to collection',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => showAddToCollectionSheet(
                context, mediaId: widget.show['id'] as String),
            ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteShow,
            ),
        ],
      ),

      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.grey.shade700,
        child: const Icon(Icons.edit),
        onPressed: () => setState(() => isEditing = true),
      ),

      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/show_view_bg.jpg",
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

  //VIEW MODE

  Widget buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Builder(
                builder: (_) {
                  final cover = coverImageProvider(imagePath);
                  if (cover == null) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.movie, size: 60),
                    );
                  }
                  return Image(
                    image: cover,
                    height: 250,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          //TITLE
          Text(
            title.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          //RATING
          Row(
            children: List.generate(5, (i) {
              return Icon(
                Icons.star,
                color: rating > i ? Colors.orange : Colors.grey.shade300,
              );
            }),
          ),

          const SizedBox(height: 20),

          Text("Genre: ${genre.text}"),
          Text("Status: ${status.text}"),
          Text("Seasons: ${seasons.text}"),

          const SizedBox(height: 20),

          const Text(
            "My Reflection",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            reflection.text.isEmpty
                ? "No reflection added."
                : reflection.text,
          ),
        ],
      ),
    );
  }

  //EDIT MODE

  Widget buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          field("Title", title),
          field("Genre", genre),
          field("Status", status),
          field("Seasons", seasons),

          const SizedBox(height: 10),

          const Text("Rating"),
          Row(
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                ),
                onPressed: () => setState(() => rating = i + 1),
              );
            }),
          ),

          field("Reflection", reflection, maxLines: 4),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                ...widget.show,
                "title": title.text,
                "genre": genre.text,
                "status": status.text,
                "seasons": seasons.text,
                "rating": rating,
                "reflection": reflection.text,
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
}