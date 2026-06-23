// ================= FILE: auth_screen.dart =================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  // ================= AUTH =================

  Future<void> auth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Заполните все поля"),
        ),
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      if (isLogin) {
        // ===== LOGIN =====

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // ===== REGISTER =====

        if (password != repeatPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Пароли не совпадают"),
            ),
          );

          setState(() {
            isLoading = false;
          });

          return;
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Ошибка авторизации",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/auth2.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(

          child: Padding(

            padding: const EdgeInsets.all(24),

            child: Center(

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // ===== TITLE =====

                    Text(
                      isLogin ? "Вход" : "Регистрация",

                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B4B4B),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== EMAIL =====

                    buildTextField(
                      controller: emailController,
                      hint: "Email",
                    ),

                    const SizedBox(height: 12),

                    // ===== PASSWORD =====

                    buildTextField(
                      controller: passwordController,
                      hint: "Пароль",
                      obscure: true,
                    ),

                    // ===== REPEAT PASSWORD =====

                    if (!isLogin) ...[

                      const SizedBox(height: 12),

                      buildTextField(
                        controller: repeatPasswordController,
                        hint: "Повторите пароль",
                        obscure: true,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ===== BUTTON =====

                    SizedBox(

                      height: 52,

                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF567799),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        onPressed: isLoading
                            ? null
                            : auth,

                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          isLogin
                              ? "Войти"
                              : "Зарегистрироваться",

                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ===== SWITCH MODE =====

                    GestureDetector(

                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },

                      child: Text(

                        isLogin
                            ? "Нет аккаунта? Зарегистрироваться"
                            : "Уже есть аккаунт? Войти",

                        style: const TextStyle(
                          color: Color(0xFF4B4B4B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= TEXTFIELD =================

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return SizedBox(

      height: 56,

      child: TextField(

        controller: controller,
        obscureText: obscure,

        decoration: InputDecoration(

          hintText: hint,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          // ОБЫЧНАЯ РАМКА
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: Color(0xFFD9D9D9),
              width: 1.5,
            ),
          ),

          // РАМКА ПРИ НАЖАТИИ
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: Color(0xFF567799),
              width: 2,
            ),
          ),

          // РАМКА ПРИ ОШИБКЕ
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
  }