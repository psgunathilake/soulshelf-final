import 'package:flutter/material.dart';

class ShowsPage extends StatelessWidget {
  const ShowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shows & Films")),
      body: const Center(child: Text("Movies & Shows Page")),
    );
  }
}
