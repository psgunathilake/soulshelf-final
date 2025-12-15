import 'package:flutter/material.dart';
import 'boook/home_page.dart';
import 'add_book_page.dart';
import 'book_view_page.dart';

class BooksDetailPage extends StatefulWidget {
  const BooksDetailPage({super.key});

  @override
  State<BooksDetailPage> createState() => _BooksDetailPageState();
}

class _BooksDetailPageState extends State<BooksDetailPage> {
  final List<Map<String, dynamic>> books = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomePage()),
                            (route) => false,
                      );
                    },
                  ),
                  const Text(
                    "Books",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.menu),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 📚 Book List
            Expanded(
              child: books.isEmpty
                  ? const Center(child: Text("No books added yet"))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return bookCard(books[index], index);
                },
              ),
            ),
          ],
        ),
      ),

      // ➕ Add Book
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookPage()),
          );

          if (result != null) {
            setState(() {
              books.add(result);
            });
          }
        },
      ),
    );
  }

  // 📦 Book Card
  Widget bookCard(Map<String, dynamic> book, int index) {
    return GestureDetector(
      onTap: () async {
        final updatedBook = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookViewPage(book: book),
          ),
        );

        if (updatedBook != null) {
          setState(() {
            books[index] = updatedBook;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book["name"],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    book["author"],
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < book["rating"]
                            ? Icons.star
                            : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
