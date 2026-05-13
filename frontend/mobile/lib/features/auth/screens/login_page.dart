import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/core/utils/validators.dart';
import 'package:soulshelf/data/repositories/auth_repository.dart';
import 'package:soulshelf/features/auth/screens/email_verification_page.dart';
import 'package:soulshelf/features/auth/screens/forgot_password_page.dart';
import 'package:soulshelf/features/auth/screens/register_page.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user.emailVerified
              ? const HomePage()
              : const EmailVerificationPage(),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// BACKGROUND IMAGE WITH LIGHT BLUR
          Stack(
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
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),

            ],
          ),


          /// MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/pin_pandas.png",
                    height: 150,
                  ),

                  const SizedBox(height: 10),

                  /// GLASS LOGIN BOX
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
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [

                            /// TOP BAR
                            Container(
                              height: 45,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC17C8A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                            ),

                            /// FORM
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [

                                    /// USERNAME
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: "User Name",
                                        labelStyle: TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    /// EMAIL
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

                                    /// PASSWORD
                                    TextFormField(
                                      controller: passwordCtrl,
                                      obscureText: obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: const TextStyle(
                                            color: Color(0x33000000)),
                                        filled: true,
                                        fillColor: Colors.white70,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              obscurePassword =
                                              !obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: Validators.loginPassword,
                                    ),

                                    /// FORGOT PASSWORD
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: forgotPassword,
                                        child: const Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                              color: Color(0x33000000)),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    /// OK BUTTON
                                    SizedBox(
                                      width: 120,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: _busy ? null : login,
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
                                                "OK",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    /// REGISTER LINK
                                    TextButton(
                                      onPressed: goToRegister,
                                      child: const Text(
                                        "Don't have an account? Register",
                                        style: TextStyle(
                                          color: Color(0x66000000),
                                          fontSize: 13,
                                        ),
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
          )
        ],
      ),
    );
  }
}