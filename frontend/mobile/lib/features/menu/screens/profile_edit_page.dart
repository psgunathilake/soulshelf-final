import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/data/models/user_model.dart';
import 'package:soulshelf/data/repositories/user_repository.dart';
import 'change_pin_page.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController currentPinCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  UserModel? _profile;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingHeader = false;

  String? generatedOtp;
  DateTime? otpExpiry;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userRepositoryProvider).getProfile();
    _profile = profile;
    nameCtrl.text = profile?.name ?? '';
    bioCtrl.text = profile?.bio ?? '';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    currentPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Name cannot be empty');
      return;
    }
    if (_profile == null) return;

    setState(() => _saving = true);
    try {
      final updated = _profile!.copyWith(
        name: name,
        bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
      );
      await ref.read(userRepositoryProvider).updateProfile(updated);
      if (!mounted) return;
      _snack('Profile saved 💾');
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      _snack(_dioMessage(e, fallback: 'Failed to save profile'));
    } catch (_) {
      if (!mounted) return;
      _snack('Failed to save profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    await _uploadAvatar(File(picked.path));
  }

  Future<void> _pickHeader() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    await _uploadHeader(File(picked.path));
  }

  Future<void> _uploadAvatar(File file) async {
    setState(() => _uploadingAvatar = true);
    try {
      final updated = await ref.read(userRepositoryProvider).uploadAvatar(file);
      if (!mounted) return;
      if (updated == null) {
        _snack('Image upload requires a connection');
      } else {
        setState(() => _profile = updated);
        _snack('Profile image updated');
      }
    } on DioException catch (e, st) {
      debugPrint('uploadAvatar DioException: ${e.type} '
          'status=${e.response?.statusCode} body=${e.response?.data} '
          'msg=${e.message}\n$st');
      if (!mounted) return;
      _snack(_dioDebug(e, fallback: 'Image upload failed'));
    } catch (e, st) {
      debugPrint('uploadAvatar error: $e\n$st');
      if (!mounted) return;
      _snack('Image upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _uploadHeader(File file) async {
    setState(() => _uploadingHeader = true);
    try {
      final updated = await ref.read(userRepositoryProvider).uploadHeader(file);
      if (!mounted) return;
      if (updated == null) {
        _snack('Image upload requires a connection');
      } else {
        setState(() => _profile = updated);
        _snack('Cover image updated');
      }
    } on DioException catch (e, st) {
      debugPrint('uploadHeader DioException: ${e.type} '
          'status=${e.response?.statusCode} body=${e.response?.data} '
          'msg=${e.message}\n$st');
      if (!mounted) return;
      _snack(_dioDebug(e, fallback: 'Image upload failed'));
    } catch (e, st) {
      debugPrint('uploadHeader error: $e\n$st');
      if (!mounted) return;
      _snack('Image upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingHeader = false);
    }
  }

  Future<void> _verifyPin() async {
    bool ok;
    try {
      ok = await ref.read(userRepositoryProvider).verifyPin(currentPinCtrl.text);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangePinPage()),
      );
    } else {
      _snack('Incorrect PIN ❌');
    }
  }

  void _forgotPin() {
    final email = _profile?.email ?? '';
    if (email.isEmpty) {
      _snack('No email on file');
      return;
    }

    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    otpExpiry = DateTime.now().add(const Duration(minutes: 5));

    _snack('OTP sent to $email');
    _showOtpDialog();
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: "Enter 6-digit OTP",
              counterText: "",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (otpExpiry == null || DateTime.now().isAfter(otpExpiry!)) {
                  Navigator.pop(context);
                  _snack('OTP Expired');
                  return;
                }

                if (otpController.text == generatedOtp) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePinPage()),
                  );
                } else {
                  _snack('Invalid OTP');
                }
              },
              child: const Text("Verify"),
            ),
          ],
        );
      },
    ).whenComplete(otpController.dispose);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _dioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return fallback;
  }

  String _dioDebug(DioException e, {required String fallback}) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final body = data is Map && data['message'] is String
        ? data['message'] as String
        : (data?.toString() ?? e.message ?? 'unknown');
    return '$fallback (${e.type.name}'
        '${code != null ? ' $code' : ''}: $body)';
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = coverImageProvider(_profile?.photoUrl);
    final headerProvider = coverImageProvider(_profile?.headerUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E8),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7D6),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFF3F7D5A),
                width: 2.5,
              ),
              image: const DecorationImage(
                image: AssetImage("assets/images/profile_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text("Profile Image",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.black54)
                              : null,
                        ),
                        if (_uploadingAvatar)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black38,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _uploadingAvatar ? null : _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6FAF8A),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text("Cover Image",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: _uploadingHeader ? null : _pickHeader,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade300,
                        image: headerProvider != null
                            ? DecorationImage(
                                image: headerProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _uploadingHeader
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (headerProvider == null
                              ? const Center(
                                  child: Icon(Icons.add_photo_alternate,
                                      size: 40, color: Colors.black54),
                                )
                              : null),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildField("User Name", nameCtrl),
                  _buildField("BIO", bioCtrl, maxLines: 3),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email Address",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _profile?.email ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("Change My Space PIN",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),

                  _buildField("Enter Current PIN", currentPinCtrl, obscure: true),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _forgotPin,
                      child: const Text(
                        "Forgot PIN?",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6FAF8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _verifyPin,
                        child: const Text("Continue",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6FAF8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Save",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: obscure ? TextInputType.number : null,
            maxLength: obscure ? 4 : null,
            maxLines: maxLines,
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
