import 'package:an_app_v1/providers/theme_provider.dart';
import 'package:an_app_v1/screens/room.dart';
import 'package:an_app_v1/services/firebase_service.dart';
import 'package:an_app_v1/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login.dart';

class MainMenu extends ConsumerStatefulWidget {
  final User user;

  const MainMenu({super.key, required this.user});

  @override
  ConsumerState<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends ConsumerState<MainMenu> {
  String username = "Yükleniyor...";
  bool isLoading = true;
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted) {
        setState(() {
          final data = snapshot.data() as Map<String, dynamic>?;
          username = data != null && data.containsKey('username')
              ? data['username']
              : 'Misafir';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          username = 'Hata oluştu';
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return 'Günaydın';
    } else if (hour >= 11 && hour < 17) {
      return 'İyi günler';
    } else if (hour >= 17 && hour < 22) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    final size = MediaQuery.of(context).size;
    final availableWidth = size.width;

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: null,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    IconButton(
                      onPressed: () async {
                        logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      icon: Icon(
                        Icons.logout_outlined,
                        color: theme.iconColor,
                        size: availableWidth * 0.1,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${getGreetingMessage()},',
                      style: TextStyle(
                        fontSize: availableWidth * 0.06,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: availableWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 125),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ne izliyoruz bakalım?",
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: availableWidth * 0.05,
                      ),
                    ),
                    const SizedBox(height: 15),
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
                          controller: _linkController,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: availableWidth * 0.04,
                          ),
                          decoration: InputDecoration(
                            hintText: "Link yapıştır...",
                            hintStyle: TextStyle(
                              fontSize: availableWidth * 0.04,
                              color: theme.placeholderColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: availableWidth * 0.04,
                              vertical: availableWidth * 0.03,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: availableWidth * 0.4,
                      height: availableWidth * 0.08,
                      child: ElevatedButton(
                        onPressed: () async {
                          String videoURL = _linkController.text;
                          String odaID =
                              await _firebaseService.odaAc(_linkController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Oda Açıldı: $odaID")));
                          Navigator.push(context,
                          MaterialPageRoute(builder: (context) => RoomScreen(videoURL: videoURL, roomId: odaID)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.textColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Oda Aç',
                          style: TextStyle(
                            fontSize: availableWidth * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
                Column(
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      "Odaya Katıl",
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: availableWidth * 0.05,
                      ),
                    ),
                    const SizedBox(height: 15),
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
                          controller: _idController,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: availableWidth * 0.04,
                          ),
                          decoration: InputDecoration(
                            hintText: "Oda Kimliği Gir",
                            hintStyle: TextStyle(
                              fontSize: availableWidth * 0.04,
                              color: theme.placeholderColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: availableWidth * 0.04,
                              vertical: availableWidth * 0.03,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: availableWidth * 0.4,
                      height: availableWidth * 0.08,
                      child: ElevatedButton(
                        onPressed: () async {
                          String? videoURL = await _firebaseService
                              .odaBilgisiAl(_idController.text);
                          if (videoURL != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RoomScreen(
                                          videoURL: videoURL,
                                          roomId: _idController.text,
                                        )));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Oda bulunamadı")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.textColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Odaya Katıl',
                          style: TextStyle(
                            fontSize: availableWidth * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: theme.bgColor.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.iconColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
