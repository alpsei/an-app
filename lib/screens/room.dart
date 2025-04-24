import 'package:an_app_v1/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

final databaseRef = FirebaseDatabase.instance.ref();

class RoomScreen extends ConsumerStatefulWidget {
  final String videoURL;
  final String roomId;

  const RoomScreen({required this.videoURL, required this.roomId, super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Stream<QuerySnapshot> _messageStream;
  late final YoutubePlayerController _controller;
  late final String? videoId;
  bool _isSyncing = false;
  late DatabaseReference _videoSyncRef;

  final FirebaseService _firebaseService = FirebaseService();

  Future<Map<String, dynamic>?> _getUpdatedUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return docSnapshot.exists ? docSnapshot.data() : null;
    } catch (e) {
      print('Kullanıcı bilgisi alınamadı: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    videoId = YoutubePlayerController.convertUrlToId(widget.videoURL);
    //print('Video ID: $videoId');
    _messageStream = _firebaseService.mesajlariDinle(widget.roomId);
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        captionLanguage: 'tr',
      ),
    );

    // Video yükleme ve otomatik başlatmayı engelle
    if (videoId != null) {
      _controller.loadVideoById(videoId: videoId!);
      _controller.pauseVideo(); // Video yüklendikten sonra duraklat
    }

    _videoSyncRef = databaseRef.child('odalar/${widget.roomId}/videoState');
    print('Firebase referansı: ${_videoSyncRef.toString()}'); // Debug için

    // Firebase bağlantısını test et
    _videoSyncRef.set({
      'test': 'bağlantı çalışıyor',
      'timestamp': ServerValue.timestamp,
    }).then((_) {
      print('Test verisi yazıldı');
    }).catchError((error) {
      print('Test verisi yazma hatası: $error');
    });

    _setupVideoSyncListener();
  }

  void _sendMessage(String message) {
    final message = _messageController.text.trim();
    //final username = 'Kullanıcı Adı';
    if (message.isNotEmpty) {
      _firebaseService.mesajGonder(widget.roomId, message);
      _messageController.clear();
    }
  }

  void _setupVideoSyncListener() {
    //print('Video senkronizasyon dinleyicisi başlatılıyor...'); // Debug için
    _videoSyncRef.onValue.listen((event) async {
      /* print(
          'Firebase değer değişikliği algılandı: ${event.snapshot.value}'); // Debug için*/

      if (_isSyncing) {
        // print('Senkronizasyon devam ediyor, işlem atlanıyor'); // Debug için
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        //print('Gelen veri null'); // Debug için
        return;
      }

      //print('Gelen veri: $data'); // Debug için

      _isSyncing = true;

      try {
        final currentVideoId = (await _controller.videoData).videoId;
        //print('Mevcut video ID: $currentVideoId'); // Debug için
        final remoteVideoId = data['videoId'] as String?;
        //print('Uzak video ID: $remoteVideoId'); // Debug için

        if (remoteVideoId != null && remoteVideoId != currentVideoId) {
          //print('Video değişiyor: $remoteVideoId'); // Debug için
          await _controller.loadVideoById(videoId: remoteVideoId);
          // Video değiştiğinde otomatik başlatma
          final remoteIsPlaying = data['isPlaying'] as bool?;
          if (remoteIsPlaying == true) {
            await _controller.playVideo();
          }
        }

        final playerState = await _controller.playerState;
        //print('Mevcut oynatıcı durumu: $playerState'); // Debug için
        final isPlaying = playerState == PlayerState.playing;
        final remoteIsPlaying = data['isPlaying'] as bool?;
        //print('Uzak oynatıcı durumu: $remoteIsPlaying'); // Debug için

        if (remoteIsPlaying != null && remoteIsPlaying != isPlaying) {
          //print('Oynatma durumu değişiyor: $remoteIsPlaying'); // Debug için
          if (remoteIsPlaying) {
            await _controller.playVideo();
          } else {
            await _controller.pauseVideo();
          }
        }

        final currentPos = await _controller.currentTime;
        //print('Mevcut pozisyon: $currentPos'); // Debug için
        final remotePos = (data['currentTime'] as num?)?.toDouble();
        //print('Uzak pozisyon: $remotePos'); // Debug için

        if (remotePos != null && (remotePos - currentPos).abs() > 0.5) {
          // Daha hassas senkronizasyon
          //print('Video pozisyonu değişiyor: $remotePos'); // Debug için
          await _controller.seekTo(seconds: remotePos);
        }
      } catch (e) {
        //print('Video senkronizasyon hatası: $e');
      } finally {
        _isSyncing = false;
      }
    }, onError: (error) {
      // print('Firebase dinleyici hatası: $error'); // Debug için
    });
  }

  Future<void> _sendPlayerStateToFirebase() async {
    if (_isSyncing) return;

    try {
      final playerState = await _controller.playerState;
      final isPlaying = playerState == PlayerState.playing;
      final position = await _controller.currentTime;
      final videoData = await _controller.videoData;

      final data = {
        'videoId': videoData.videoId,
        'isPlaying': isPlaying,
        'currentTime': position,
        'lastUpdated': ServerValue.timestamp,
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      // print('Gönderilen veri: $data'); // Debug için

      await _videoSyncRef.set(data);
    } catch (e) {
      //print('Firebase güncelleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    final size = MediaQuery.of(context).size;
    final availableWidth = size.width;
    final availableHeight = size.height;
    final FocusNode _focusNode = FocusNode();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return YoutubePlayerScaffold(
        controller: _controller,
        builder: (context, player) {
          final theme = Theme.of(context).extension<AppTheme>()!;
          _controller.listen((event) {
            if (event.playerState == PlayerState.playing ||
                event.playerState == PlayerState.paused) {
              _sendPlayerStateToFirebase();
            }
          });

          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: theme.bgColor,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    top: availableHeight * 0.35,
                    bottom: keyboardHeight + availableHeight * 0.12,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('odalar')
                          .doc(widget.roomId)
                          .collection('mesajlar')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('Henüz mesaj yok.'));
                        }

                        final messages = snapshot.data!.docs;

                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.only(bottom: 10),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUserMessage =
                                message['gonderenUid'] ==
                                    FirebaseAuth.instance.currentUser?.uid;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: Row(
                                mainAxisAlignment: isCurrentUserMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 5),
                                          child: Text(
                                            message['gonderen'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isCurrentUserMessage
                                                  ? theme.textColor
                                                  : theme.textColor,
                                            ),
                                          ),
                                        ),
                                        // Mesaj balonu
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isCurrentUserMessage
                                                ? theme.oppositeMessageBalloon
                                                : theme.messageColor,
                                            borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(12),
                                              topRight:
                                                  const Radius.circular(12),
                                              bottomLeft:
                                                  const Radius.circular(12),
                                              bottomRight: Radius.circular(
                                                  isCurrentUserMessage
                                                      ? 12
                                                      : 0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 5),
                                              Text(
                                                message['mesaj'],
                                                style: TextStyle(
                                                  color: isCurrentUserMessage
                                                      ? theme.messageText
                                                      : theme.messageText,
                                                ),
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                message['timestamp'] != null
                                                    ? DateFormat('HH:mm')
                                                        .format(
                                                            message['timestamp']
                                                                .toDate())
                                                    : '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isCurrentUserMessage
                                                      ? theme.placeholderColor
                                                      : theme.placeholderColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: availableHeight * 0.15,
                    left: 0,
                    right: 0,
                    child: SizedBox(child: player),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 40, left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                            icon: Consumer(
                              builder: (context, ref, child) {
                                final isDarkMode = ref.watch(themeProvider) ==
                                    AppThemeType.dark;
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
                          TextButton(
                            onPressed: () async {
                              final updatedUser = await _getUpdatedUser();
                              Navigator.pop(context, updatedUser);
                            },
                            child: Text(
                              "Bitir",
                              style: TextStyle(
                                  color: theme.finishButton, fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: keyboardHeight > 0
                        ? keyboardHeight
                        : availableHeight * 0.05,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
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
                                controller: _messageController,
                                obscureText: false,
                                focusNode: _focusNode,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Mesaj Yaz...",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: availableWidth * 0.04,
                                    vertical: availableWidth * 0.03,
                                  ),
                                ),
                                cursorHeight: 20,
                                textAlignVertical: TextAlignVertical.center,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: theme.iconColor),
                            onPressed: () {
                              final message = _messageController.text;
                              if (message.isNotEmpty) {
                                _sendMessage(message);
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  @override
  void dispose() {
    _videoSyncRef.onDisconnect().cancel();
    _controller.close();
    super.dispose();
  }
}
