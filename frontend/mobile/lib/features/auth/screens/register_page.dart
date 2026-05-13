import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/core/utils/validators.dart';
import 'package:soulshelf/data/repositories/auth_repository.dart';
import 'package:soulshelf/features/auth/screens/email_verification_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool _busy = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).register(
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong. ($e)')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/entrance_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset("assets/images/pin_pandas.png", height: 130),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 320,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 45,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC17C8A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: "Name",
                                        labelStyle: TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                      ),
                                      validator: (v) => Validators.required(v,
                                          fieldName: 'Name'),
                                    ),
                                    const SizedBox(height: 15),
                                    TextFormField(
                                      controller: emailCtrl,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: "Email",
                                        labelStyle: TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                      ),
                                      validator: Validators.email,
                                    ),
                                    const SizedBox(height: 15),
                                    TextFormField(
                                      controller: passwordCtrl,
                                      obscureText: obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: const TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                        helperText:
                                            "8+ chars, 1 uppercase, 1 digit",
                                        helperStyle: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0x66000000)),
                                        suffixIcon: IconButton(
                                          icon: Icon(obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off),
                                          onPressed: () => setState(() =>
                                              obscurePassword =
                                                  !obscurePassword),
                                        ),
                                      ),
                                      validator: Validators.password,
                                    ),
                                    const SizedBox(height: 15),
                                    TextFormField(
                                      controller: confirmCtrl,
                                      obscureText: obscureConfirm,
                                      decoration: InputDecoration(
                                        labelText: "Confirm Password",
                                        labelStyle: const TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                        suffixIcon: IconButton(
                                          icon: Icon(obscureConfirm
                                              ? Icons.visibility
                                              : Icons.visibility_off),
                                          onPressed: () => setState(() =>
                                              obscureConfirm =
                                                  !obscureConfirm),
                                        ),
                                      ),
                                      validator: (v) =>
                                          Validators.confirmPassword(
                                              v, passwordCtrl.text),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 160,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: _busy ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFC17C8A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                "Register",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "Already have an account? Login",
                                        style: TextStyle(
                                            color: Color(0x66000000),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
