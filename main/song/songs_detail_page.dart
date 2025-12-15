import 'dart:io';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'add_song_page.dart';
import 'song_view_page.dart';

class SongsDetailPage extends StatefulWidget {
  const SongsDetailPage({super.key});

  @override
  State<SongsDetailPage> createState() => _SongsDetailPageState();
}

class _SongsDetailPageState extends State<SongsDetailPage> {
  final List<Map<String, dynamic>> songs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔝 TOP BAR WITH HOME BUTTON
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        title: const Text("Music"),
        centerTitle: true,
      ),

      body: songs.isEmpty
          ? const Center(child: Text("No songs added yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return songCard(songs[index], index);
        },
      ),

      // ➕ ADD SONG
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final song = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSongPage()),
          );

          if (song != null) {
            setState(() => songs.add(song));
          }
        },
      ),
    );
  }

  // 🎵 SONG CARD
  Widget songCard(Map<String, dynamic> song, int index) {
    return GestureDetector(
      onTap: () async {
        final updatedSong = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongViewPage(song: song),
          ),
        );

        if (updatedSong != null) {
          setState(() => songs[index] = updatedSong);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // 🖼️ COVER IMAGE
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
                image: song["imagePath"] != null
                    ? DecorationImage(
                  image: FileImage(File(song["imagePath"])),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: song["imagePath"] == null
                  ? const Icon(Icons.music_note)
                  : null,
            ),

            const SizedBox(width: 12),

            // 🎶 TITLE + RATING
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song["title"] == null || song["title"].isEmpty
                        ? "Untitled Song"
                        : song["title"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < (song["rating"] ?? 0)
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
