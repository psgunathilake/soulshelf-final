import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/cover_image_provider.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/repositories/collection_repository.dart';

/// Single screen for both creating and editing a collection. When
/// `existing` is null we're in create mode; otherwise we pre-fill from
/// the model. Cover handling mirrors media's save-then-upload (3.10
/// pattern) — the row is persisted first, then the cover is uploaded
/// against the assigned id. Offline saves return a local-uuid row;
/// cover upload is silently skipped in that case.
class CollectionFormPage extends ConsumerStatefulWidget {
  const CollectionFormPage({super.key, this.existing});
  final CollectionModel? existing;

  @override
  ConsumerState<CollectionFormPage> createState() => _CollectionFormPageState();
}

class _CollectionFormPageState extends ConsumerState<CollectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  File? _newCover;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _newCover = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(collectionRepositoryProvider);
    final now = DateTime.now();

    try {
      String savedId;
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          name: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          updatedAt: now,
        );
        await repo.updateCollection(updated);
        savedId = updated.id;
      } else {
        final created = await repo.addCollection(CollectionModel(
          id: '',
          name: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          createdAt: now,
          updatedAt: now,
        ));
        savedId = created.id;
      }

      if (_newCover != null) {
        // Skip server upload for offline-only rows. The user can re-edit
        // once the queue drains and try again.
        if (!savedId.startsWith('local-')) {
          await repo.uploadCover(savedId, _newCover!);
        }
      }

      if (!mounted) return;
      // Return the saved id so callers (e.g. add-to-collection sheet) can
      // chain a follow-up like attachMedia. The list page's FAB ignores it.
      Navigator.pop(context, savedId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingCover = coverImageProvider(widget.existing?.coverUrl);
    final preview = _newCover != null
        ? FileImage(_newCover!) as ImageProvider
        : existingCover;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit collection' : 'New collection'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickCover,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: preview == null
                      ? Container(
                          color: const Color(0xFFEDE7F6),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                size: 38, color: Colors.black45),
                              SizedBox(height: 6),
                              Text('Tap to add a cover',
                                style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      : Image(image: preview, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
}
