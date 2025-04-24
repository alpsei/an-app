import 'package:an_app_v1/providers/theme_provider.dart';
import 'package:an_app_v1/screens/main_menu.dart';
import 'package:an_app_v1/screens/register.dart';
import 'package:an_app_v1/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /*final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();*/
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> loginUser() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      // Boş alan kontrolü
      if (username.isEmpty || password.isEmpty) {
        _showDialog("Kullanıcı adı veya şifre boş bırakılamaz.");
        return;
      }

      // Kullanıcı adını email formatına çeviriyoruz
      String email = '${username.trim()}@yourdomain.com'.toLowerCase();

      // Firebase ile giriş yapma
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
      // Giriş başarılıysa MainMenu'ye yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(user: userCredential.user!),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Giriş hatası: ';

      // Firebase hata kodlarına göre özelleştirilmiş mesajlar
      if (e.code == 'user-not-found') {
        errorMessage += 'Kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        errorMessage += 'Yanlış şifre.';
      } else if (e.code == 'too-many-requests') {
        errorMessage +=
            'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      } else {
        errorMessage += e.message ?? 'Bilinmeyen hata';
      }

      _showDialog(errorMessage);
    } catch (e) {
      _showDialog('Beklenmeyen hata: ${e.toString()}');
    }
  }

  void _showDialog(String message) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: theme.bgColor,
            title: Text('Bilgi', style: TextStyle(color: theme.textColor)),
            content: Text(message, style: TextStyle(color: theme.textColor)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Tamam',
                  style: TextStyle(color: theme.textColor),
                ),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    final size = MediaQuery.of(context).size;
    final availableWidth = size.width;
    final availableHeight = size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.bgColor,
      appBar: null,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        icon: Consumer(
                          builder: (context, ref, child) {
                            final isDarkMode =
                                ref.watch(themeProvider) == AppThemeType.dark;
                            return Icon(
                              isDarkMode
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: theme.iconColor,
                              size: availableWidth * 0.1,
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "İyi Günler!",
                          style: TextStyle(
                            fontSize: availableWidth * 0.06,
                            color: theme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 250),
                ],
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: theme.iconColor),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: availableWidth * 0.25,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Kullanıcı Adı:",
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: availableWidth * 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.textFieldColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(5, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _usernameController,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16,
                                height: 0.04,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: availableWidth * 0.04,
                                  vertical: availableWidth * 0.03,
                                ),
                                isDense: true,
                              ),
                              cursorHeight: 20,
                              textAlignVertical: TextAlignVertical.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: theme.iconColor),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: availableWidth * 0.25,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Şifre:",
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: availableWidth * 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.textFieldColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(5, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16,
                                height: 0.05,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: availableWidth * 0.04,
                                  vertical: availableWidth * 0.03,
                                ),
                                isDense: true,
                              ),
                              cursorHeight: 20,
                              textAlignVertical: TextAlignVertical.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
              left: 0,
              right: 0,
              bottom: availableHeight * 0.05,
              child: Column(
                children: [
                  Center(child: RichText(text: TextSpan(
                    text: "Hesabın yok mu? Kaydol!",
                    style: TextStyle(color: theme.textColor, fontSize: 18),
                    recognizer: TapGestureRecognizer()..onTap = (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()),);
                    }
                  ))),
                  const SizedBox(height: 35,),
                  Center(
                    child: SizedBox(
                      width: availableWidth * 0.3,
                      height: availableWidth * 0.08,
                      child: ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.textColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Giriş Yap'),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
