import 'package:an_app_v1/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isCurrentUserMessage;
  final AppTheme theme;
  final Function(String, String) onQuote;

  const MessageBubble({
    required this.data,
    required this.isCurrentUserMessage,
    required this.theme,
    required this.onQuote,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  final double _maxDragOffset = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, _maxDragOffset);
      _animation = Tween<double>(begin: 0.0, end: _dragOffset).animate(_animationController);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > _maxDragOffset * 0.5) {
      // Trigger the quote and print debug info
      print('Quote triggered from MessageBubble: ${widget.data['mesaj']}');
      widget.onQuote(widget.data['mesaj'], widget.data['gonderen']);
    }

    setState(() {
      _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(_animationController);
      _dragOffset = 0.0;
    });

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isCurrentUserMessage
                    ? widget.theme.oppositeMessageBalloon
                    : widget.theme.messageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: Radius.circular(
                      widget.isCurrentUserMessage ? 12 : 0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  if (widget.data.containsKey('replyTo') &&
                      widget.data['replyTo'] != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data['replyTo']['senderUsername'] ??
                                'Bilinmeyen',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.data['replyTo']['messageText'] ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    widget.data['mesaj'] ?? 'Mesaj Boş',
                    style: TextStyle(
                      color: widget.isCurrentUserMessage
                          ? widget.theme.messageText
                          : widget.theme.messageText,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.data['timestamp'] != null
                        ? DateFormat('HH:mm')
                        .format(widget.data['timestamp'].toDate())
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isCurrentUserMessage
                          ? widget.theme.placeholderColor
                          : widget.theme.placeholderColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class QuoteBox extends StatelessWidget {
  final String? message;
  final String? sender;
  final VoidCallback onCancel;

  const QuoteBox({
    required this.message,
    required this.sender,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || sender == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message!,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _RoomScreenState extends ConsumerState<RoomScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late Stream<QuerySnapshot> _messageStream;
  late final YoutubePlayerController _controller;
  late final String? videoId;
  bool _isSyncing = false;
  late DatabaseReference _videoSyncRef;

  // ValueNotifiers for quote functionality
  final ValueNotifier<String?> _quoteMessageNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _quoteSenderNotifier = ValueNotifier<String?>(null);

  final Map<String, double> _messageOffsets = {};
  final double _maxSwipeOffset = 100.0;
  final GlobalKey _messageKey = GlobalKey();
  String? _currentlySwipedMessageId;
  late AnimationController _animationController;
  final Map<String, Animation<double>> _animations = {};

  final FirebaseService _firebaseService = FirebaseService();
  final FocusNode _focusNode = FocusNode();

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    videoId = YoutubePlayerController.convertUrlToId(widget.videoURL);
    _messageStream = _firebaseService.mesajlariDinle(widget.roomId);
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        captionLanguage: 'tr',
      ),
    );

    if (videoId != null) {
      _controller.loadVideoById(videoId: videoId!);
      _controller.pauseVideo();
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
    final messageText = message.trim();
    if (messageText.isNotEmpty) {
      final messageData = {
        'mesaj': messageText,
        'gonderen': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonim',
        'gonderenUid': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add quote data if available
      if (_quoteMessageNotifier.value != null && _quoteSenderNotifier.value != null) {
        messageData['replyTo'] = {
          'messageText': _quoteMessageNotifier.value,
          'senderUsername': _quoteSenderNotifier.value,
        };
      }

      _firebaseService.mesajGonder(widget.roomId, messageData);
      _messageController.clear();

      // Clear quote after sending
      _cancelQuote();
    }
  }

  void _setupVideoSyncListener() {
    _videoSyncRef.onValue.listen((event) async {
      if (_isSyncing) {
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return;
      }

      _isSyncing = true;

      try {
        final currentVideoId = (await _controller.videoData).videoId;
        final remoteVideoId = data['videoId'] as String?;

        if (remoteVideoId != null && remoteVideoId != currentVideoId) {
          await _controller.loadVideoById(videoId: remoteVideoId);
          final remoteIsPlaying = data['isPlaying'] as bool?;
          if (remoteIsPlaying == true) {
            await _controller.playVideo();
          }
        }

        final playerState = await _controller.playerState;
        final isPlaying = playerState == PlayerState.playing;
        final remoteIsPlaying = data['isPlaying'] as bool?;

        if (remoteIsPlaying != null && remoteIsPlaying != isPlaying) {
          if (remoteIsPlaying) {
            await _controller.playVideo();
          } else {
            await _controller.pauseVideo();
          }
        }

        final currentPos = await _controller.currentTime;
        final remotePos = (data['currentTime'] as num?)?.toDouble();

        if (remotePos != null && (remotePos - currentPos).abs() > 0.5) {
          await _controller.seekTo(seconds: remotePos);
        }
      } catch (e) {
        print('Video senkronizasyon hatası: $e');
      } finally {
        _isSyncing = false;
      }
    }, onError: (error) {
      print('Firebase dinleyici hatası: $error');
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

      await _videoSyncRef.set(data);
    } catch (e) {
      print('Firebase güncelleme hatası: $e');
    }
  }

  void _handleQuote(String message, String sender) {
    print('_handleQuote called with message: $message, sender: $sender');
    // Update both ValueNotifiers to trigger UI updates
    _quoteMessageNotifier.value = message;
    _quoteSenderNotifier.value = sender;
  }

  void _cancelQuote() {
    print('_cancelQuote called');
    _quoteMessageNotifier.value = null;
    _quoteSenderNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    final size = MediaQuery.of(context).size;
    final availableWidth = size.width;
    final availableHeight = size.height;
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
            child: Column(
              children: [
                // Top section with theme toggle and exit button
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                  child: Row(
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

                // Video player section
                SizedBox(
                  height: availableHeight * 0.3,
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // 16:9 oranı
                    child: player,
                  ),
                ),

                // Messages section
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('odalar')
                        .doc(widget.roomId)
                        .collection('mesajlar')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          final data = message.data() as Map<String, dynamic>;
                          if (data != null) {
                            final isCurrentUserMessage = data['gonderenUid'] ==
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
                                            data['gonderen'] ?? 'Bilinmeyen',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isCurrentUserMessage
                                                  ? theme.textColor
                                                  : theme.textColor,
                                            ),
                                          ),
                                        ),
                                        // Mesaj balonu
                                        MessageBubble(
                                          data: data,
                                          isCurrentUserMessage: isCurrentUserMessage,
                                          theme: theme,
                                          onQuote: _handleQuote,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      );
                    },
                  ),
                ),

                // Input section with quote box and message field
                Padding(
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight > 0 ? keyboardHeight : 8,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quote box - using ValueListenableBuilder to update when quote changes
                      ValueListenableBuilder<String?>(
                        valueListenable: _quoteMessageNotifier,
                        builder: (context, quoteMessage, _) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: _quoteSenderNotifier,
                            builder: (context, quoteSender, _) {
                              if (quoteMessage != null && quoteSender != null) {
                                return QuoteBox(
                                  message: quoteMessage,
                                  sender: quoteSender,
                                  onCancel: _cancelQuote,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // Message text field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        child: Row(
                          children: [
                            Expanded(
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
                            IconButton(
                              icon: Icon(Icons.send, color: theme.iconColor),
                              onPressed: () {
                                final message = _messageController.text;
                                if (message.isNotEmpty) {
                                  _sendMessage(message);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4), // Extra padding at the bottom
                    ],
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
    _animationController.dispose();
    _videoSyncRef.onDisconnect().cancel();
    _controller.close();
    _focusNode.dispose();
    super.dispose();
  }
}