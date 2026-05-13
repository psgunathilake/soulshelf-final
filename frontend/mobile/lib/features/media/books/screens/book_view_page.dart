import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/features/collections/widgets/add_to_collection_sheet.dart';

class BookViewPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookViewPage({super.key, required this.book});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage>
    with SingleTickerProviderStateMixin {

  late TextEditingController nameController;
  late TextEditingController authorController;
  late TextEditingController pagesController;
  late TextEditingController notesController;

  late int rating;
  late String status;
  String? imagePath;
  String? genre;

  DateTime? startDate;
  DateTime? endDate;

  bool isEditing = false;

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color mainColor = const Color(0xFFF3E5D8);
  final Color darkAccent = const Color(0xFF8D6E63);
  final Color softBackground = const Color(0xFFFFF8F2);
  final Color cardColor = const Color(0xFFFFE0B2);
  final Color buttonColor = const Color(0xFFD7A86E);
  final Color textPrimary = const Color(0xFF5D4037);
  final Color borderColor = const Color(0xFFE6CFC2);

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.book["name"]);
    authorController = TextEditingController(text: widget.book["author"]);
    pagesController =
        TextEditingController(text: widget.book["pages"] ?? "");
    notesController =
        TextEditingController(text: widget.book["notes"] ?? "");

    rating = widget.book["rating"] ?? 0;
    status = widget.book["status"] ?? "ongoing";
    imagePath = widget.book["image"];
    genre = widget.book["genre"];

    startDate = widget.book["startDate"] != null
        ? DateTime.parse(widget.book["startDate"])
        : null;

    endDate = widget.book["endDate"] != null
        ? DateTime.parse(widget.book["endDate"])
        : null;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkAccent),
        title: Text(
          "Book Details",
          style: TextStyle(color: textPrimary),
        ),
        actions: [
          if (!isEditing && widget.book['id'] != null)
            IconButton(
              tooltip: 'Add to collection',
              icon: Icon(Icons.bookmark_add_outlined, color: darkAccent),
              onPressed: () => showAddToCollectionSheet(
                context, mediaId: widget.book['id'] as String),
            ),
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: darkAccent),
              onPressed: deleteBook,
            ),
        ],
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        backgroundColor: buttonColor,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          setState(() {
            isEditing = true;
          });
        },
      ),

      // BACKGROUND IMAGE
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/images/book_view_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha:0.35),
            ),
          ),

          SafeArea(
            child: isEditing ? buildEditMode() : buildViewMode(),
          ),

        ],
      ),
    );
  }

  Widget buildViewMode() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Builder(
                builder: (_) {
                  final cover = coverImageProvider(imagePath);
                  if (cover == null) return const SizedBox.shrink();
                  return Center(
                    child: Container(
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: cover,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                nameController.text,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "by ${authorController.text}",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: darkAccent,
                ),
              ),

              const SizedBox(height: 10),

              if (genre != null)
                cuteChip("📚 $genre"),

              const SizedBox(height: 20),

              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: buttonColor,
                    size: 28,
                  );
                }),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 10,
                children: [
                  cuteChip("🌸 ${status.toUpperCase()}"),
                  if (pagesController.text.isNotEmpty)
                    cuteChip("📄 ${pagesController.text} pages"),
                ],
              ),

              const SizedBox(height: 20),

              if (startDate != null || endDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18,
                        color: darkAccent),
                    const SizedBox(width: 8),
                    Text(
                      "${startDate != null ? formatter.format(startDate!) : ""}"
                          "  -  "
                          "${endDate != null ? formatter.format(endDate!) : ""}",
                      style: TextStyle(color: textPrimary),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              Text(
                "✨ My Reflection",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: softBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  notesController.text.isEmpty
                      ? "No reflection written yet..."
                      : notesController.text,
                  style: TextStyle(
                    height: 1.5,
                    color: textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget cuteChip(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(color: textPrimary),
      ),
    );
  }

  Widget buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildField("Book Name", nameController),
          buildField("Author", authorController),
          const SizedBox(height: 15),
          Text("Rating", style: TextStyle(color: textPrimary)),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < rating
                      ? Icons.star
                      : Icons.star_border,
                  color: buttonColor,
                ),
                onPressed: () =>
                    setState(() => rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 15),
          buildField("Number of Pages", pagesController,
              keyboard: TextInputType.number),
          buildField("Notes", notesController, maxLines: 4),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: saveUpdatedBook,
              child: const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textPrimary)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            filled: true,
            fillColor: softBackground,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: darkAccent),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  void saveUpdatedBook() {
    Navigator.pop(context, {
      "name": nameController.text,
      "author": authorController.text,
      "rating": rating,
      "status": status,
      "genre": genre,
      "image": imagePath,
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
      "pages": pagesController.text,
      "notes": notesController.text,
    });
  }

  void deleteBook() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Book"),
          content: const Text(
            "Are you sure you want to delete this book?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
}