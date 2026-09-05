import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'firebase_options.dart';

/// ============================================================
/// AGORA
/// ============================================================
/// ضع Agora App ID هنا
const String agoraAppId = 'PUT_YOUR_AGORA_APP_ID_HERE';

/// إذا كنت تستخدم Temporary Token من Agora Console ضعه هنا.
/// إذا كان مشروعك يعمل بدون Token في وضع الاختبار يمكن تركه null.
const String? agoraToken = null;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MazaajApp());
}

// ============================================================
// APP
// ============================================================

class MazaajApp extends StatelessWidget {
  const MazaajApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزاج',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();

  bool registerMode = false;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final nickname = nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('اكتب الإيميل وكلمة المرور');
      return;
    }

    if (registerMode && nickname.isEmpty) {
      showMessage('اكتب الاسم المستعار');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      UserCredential credential;

      if (registerMode) {
        credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': email,
            'nickname': nickname,
            'points': 0,
            'level': 1,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;

        if (user != null) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);

          final doc = await ref.get();

          if (!doc.exists) {
            await ref.set({
              'uid': user.uid,
              'email': email,
              'nickname': email.split('@').first,
              'points': 0,
              'level': 1,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'حدث خطأ في تسجيل الدخول');
    } catch (e) {
      showMessage('حدث خطأ: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.forum,
                  size: 80,
                ),
                const SizedBox(height: 15),
                const Text(
                  'مزاج',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'دردشة وألعاب أونلاين 🎮',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 35),
                if (registerMode)
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم المستعار',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (registerMode)
                  const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'الإيميل',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const CircularProgressIndicator()
                          : Text(
                              registerMode
                                  ? 'إنشاء حساب'
                                  : 'تسجيل الدخول',
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            registerMode = !registerMode;
                          });
                        },
                  child: Text(
                    registerMode
                        ? 'عندي حساب - تسجيل الدخول'
                        : 'إنشاء حساب جديد',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// USER PROFILE
// ============================================================

Future<Map<String, dynamic>> getCurrentUserProfile() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return {};
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data() ?? {};
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    RoomsListPage(),
    GamesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room),
            label: 'الغرف',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports),
            label: 'الألعاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ROOMS
// ============================================================

class RoomsListPage extends StatelessWidget {
  const RoomsListPage({super.key});

  Future<void> createRoom(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إنشاء غرفة'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم الغرفة',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(
                    context,
                    controller.text.trim(),
                  );
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    await FirebaseFirestore.instance.collection('rooms').add({
      'name': name,
      'ownerId': user.uid,
      'ownerNickname': profile['nickname'] ?? 'لاعب',
      'membersCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'غرف مزاج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => createRoom(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطأ: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final rooms = snapshot.data?.docs ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد غرف حالياً\nأنشئ أول غرفة 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room =
                  rooms[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.forum),
                  ),
                  title: Text(
                    room['name'] ?? 'غرفة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '👥 ${room['membersCount'] ?? 0} أعضاء',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          roomId: rooms[index].id,
                          roomName: room['name'] ?? 'غرفة',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// CHAT ROOM
// ============================================================

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final messageController = TextEditingController();

  String? currentNickname;

  @override
  void initState() {
    super.initState();
    loadProfile();
    joinRoom();
  }

  Future<void> loadProfile() async {
    final data = await getCurrentUserProfile();

    if (mounted) {
      setState(() {
        currentNickname = data['nickname'] ?? 'لاعب';
      });
    }
  }

  Future<void> joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('members')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'nickname': profile['nickname'] ?? 'لاعب',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({
      'membersCount': FieldValue.increment(1),
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || user == null) return;

    final profile = await getCurrentUserProfile();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'uid': user.uid,
      'nickname': profile['nickname'] ?? 'لاعب',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          // ==================================================
          // VOICE STAGE
          // ==================================================
          IconButton(
            tooltip: 'المنصة الصوتية',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceStagePage(
                    roomId: widget.roomId,
                    roomName: widget.roomName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.mic),
          ),

          // ==================================================
          // GAMES
          // ==================================================
          IconButton(
            tooltip: 'الألعاب',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomGamesPage(
                    roomId: widget.roomId,
                    roomName: widget.roomName,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.sports_esports,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'ابدأ المحادثة 👋',
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data()
                            as Map<String, dynamic>;

                    final user =
                        FirebaseAuth.instance.currentUser;

                    final mine =
                        data['uid'] == user?.uid;

                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(14),
                          color: mine
                              ? Colors.deepPurple
                              : Colors.grey.shade800,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                data['nickname'] ??
                                    'لاعب',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            Text(
                              data['text'] ?? '',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'اكتب رسالتك...',
                        border:
                            OutlineInputBorder(),
                      ),
                      onSubmitted: (_) =>
                          sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VOICE STAGE
// ============================================================

class VoiceStagePage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const VoiceStagePage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<VoiceStagePage> createState() =>
      _VoiceStagePageState();
}

class _VoiceStagePageState
    extends State<VoiceStagePage> {
  late final RtcEngine _engine;

  bool engineReady = false;
  bool joinedVoice = false;
  bool muted = true;
  bool isOwner = false;

  String nickname = 'لاعب';

  final List<int> micSlots = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    initializeVoice();
  }

  Future<void> initializeVoice() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    nickname = profile['nickname'] ?? 'لاعب';

    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();

    final roomData = roomDoc.data() ?? {};

    isOwner = roomData['ownerId'] == user.uid;

    await createVoiceEngine();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('participants')
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'nickname': nickname,
      'role': isOwner ? 'speaker' : 'listener',
      'slot': isOwner ? 1 : null,
      'muted': true,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isOwner) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('stage')
          .doc('state')
          .set({
        'slot1': user.uid,
      }, SetOptions(merge: true));
    }

    await joinAgoraChannel();
  }

  Future<void> createVoiceEngine() async {
    if (agoraAppId == 'PUT_YOUR_AGORA_APP_ID_HERE') {
      if (mounted) {
        setState(() {
          engineReady = false;
        });
      }
      return;
    }

    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
        channelProfile:
            ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (err, msg) {
          debugPrint(
            'Agora error: $err - $msg',
          );
        },
        onJoinChannelSuccess:
            (connection, elapsed) {
          debugPrint(
            'Joined voice channel',
          );
        },
      ),
    );

    await _engine.enableAudio();

    engineReady = true;
  }

  Future<void> joinAgoraChannel() async {
    if (!engineReady) return;

    try {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
      );

      await _engine.joinChannel(
        token: agoraToken,
        channelId: widget.roomId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType:
              ClientRoleType.clientRoleAudience,
          publishMicrophoneTrack: false,
        ),
      );

      if (mounted) {
        setState(() {
          joinedVoice = true;
        });
      }
    } catch (e) {
      debugPrint(
        'Agora join error: $e',
      );
    }
  }

  Future<void> becomeSpeaker(
    String uid,
    int slot,
  ) async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    if (!isOwner) return;

    final participantRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('participants')
            .collection('users')
            .doc(uid);

    final stageRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('state');

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
      final stageSnapshot =
          await transaction.get(stageRef);

      final stageData =
          stageSnapshot.data()
              as Map<String, dynamic>? ??
              {};

      if (stageData['slot$slot'] != null) {
        throw Exception(
          'هذا المايك مستخدم',
        );
      }

      transaction.set(
        stageRef,
        {
          'slot$slot': uid,
        },
        SetOptions(merge: true),
      );

      transaction.set(
        participantRef,
        {
          'role': 'speaker',
          'slot': slot,
          'muted': false,
        },
        SetOptions(merge: true),
      );
    });

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('requests')
        .collection('users')
        .doc(uid)
        .delete()
        .catchError((_) {});

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('participants')
        .collection('users')
        .doc(uid)
        .set({
      'role': 'speaker',
      'slot': slot,
    }, SetOptions(merge: true));
  }

  Future<void> requestMic() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('requests')
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'nickname': nickname,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✋ تم إرسال طلب المايك',
          ),
        ),
      );
    }
  }

  Future<void> leaveMic() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final participantRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('participants')
            .collection('users')
            .doc(user.uid);

    final stageRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('state');

    final participant =
        await participantRef.get();

    final data = participant.data() ?? {};

    final slot = data['slot'];

    if (slot != null) {
      await stageRef.update({
        'slot$slot':
            FieldValue.delete(),
      });
    }

    await participantRef.set({
      'role': 'listener',
      'slot': null,
      'muted': true,
    }, SetOptions(merge: true));

    if (engineReady) {
      await _engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
      );

      await _engine.muteLocalAudioStream(true);
    }

    if (mounted) {
      setState(() {
        muted = true;
      });
    }
  }

  Future<void> toggleMute() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final participantRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('participants')
            .collection('users')
            .doc(user.uid);

    final doc =
        await participantRef.get();

    final data = doc.data() ?? {};

    if (data['role'] != 'speaker') {
      return;
    }

    final newMuted = !muted;

    await participantRef.set({
      'muted': newMuted,
    }, SetOptions(merge: true));

    if (engineReady) {
      await _engine.muteLocalAudioStream(
        newMuted,
      );
    }

    if (mounted) {
      setState(() {
        muted = newMuted;
      });
    }
  }

  Future<void> demoteSpeaker(
    String uid,
    int slot,
  ) async {
    if (!isOwner) return;

    final participantRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('participants')
            .collection('users')
            .doc(uid);

    final stageRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('state');

    await participantRef.set({
      'role': 'listener',
      'slot': null,
      'muted': true,
    }, SetOptions(merge: true));

    await stageRef.set({
      'slot$slot': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> muteSpeaker(
    String uid,
    bool value,
  ) async {
    if (!isOwner) return;

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('participants')
        .collection('users')
        .doc(uid)
        .set({
      'muted': value,
    }, SetOptions(merge: true));
  }

  Widget micCard(
    int slot,
    Map<String, dynamic>? participant,
  ) {
    final uid = participant?['uid'];
    final name =
        participant?['nickname'] ?? 'المايك فارغ';
    final isMuted =
        participant?['muted'] ?? true;

    return GestureDetector(
      onTap: () {
        if (isOwner &&
            uid != null &&
            uid != FirebaseAuth.instance.currentUser?.uid) {
          showSpeakerMenu(
            uid,
            name,
            slot,
            isMuted,
          );
        }
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 10,
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 29,
                child: Icon(
                  uid == null
                      ? Icons.mic_none
                      : isMuted
                          ? Icons.mic_off
                          : Icons.mic,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'مايك $slot',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (uid != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4),
                  child: Text(
                    isMuted
                        ? '🔇 مكتوم'
                        : '🎙️ يتكلم',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showSpeakerMenu(
    String uid,
    String name,
    int slot,
    bool isMuted,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  isMuted
                      ? Icons.mic
                      : Icons.mic_off,
                ),
                title: Text(
                  isMuted
                      ? 'فتح المايك'
                      : 'كتم المايك',
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await muteSpeaker(
                    uid,
                    !isMuted,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove,
                ),
                title: const Text(
                  'إنزال من المنصة',
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await demoteSpeaker(
                    uid,
                    slot,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget requestCard(
    Map<String, dynamic> data,
  ) {
    final uid = data['uid'] ?? '';
    final name =
        data['nickname'] ?? 'لاعب';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.pan_tool),
        ),
        title: Text(name),
        subtitle: const Text(
          'يريد الصعود للمايك',
        ),
        trailing: isOwner
            ? ElevatedButton(
                onPressed: () async {
                  final slot =
                      await findFreeSlot();

                  if (slot == null) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'كل المايكات الخمسة مشغولة 🎤',
                        ),
                      ),
                    );

                    return;
                  }

                  try {
                    await becomeSpeaker(
                      uid,
                      slot,
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'تعذر قبول الطلب: $e',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'قبول',
                ),
              )
            : null,
      ),
    );
  }

  Future<int?> findFreeSlot() async {
    final stageRef =
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('state');

    final doc = await stageRef.get();

    final data = doc.data() ?? {};

    for (final slot in micSlots) {
      if (data['slot$slot'] == null) {
        return slot;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎙️ ${widget.roomName}',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('stage')
            .doc('participants')
            .collection('users')
            .snapshots(),
        builder: (context, participantSnapshot) {
          final participants =
              participantSnapshot.data?.docs ?? [];

          final Map<String, Map<String, dynamic>>
              participantMap = {};

          for (final doc in participants) {
            participantMap[doc.id] = {
              ...doc.data(),
              'uid': doc.id,
            };
          }

          final me =
              participantMap[user?.uid ?? ''];

          final myRole =
              me?['role'] ?? 'listener';

          final myMuted =
              me?['muted'] ?? true;

          if (muted != myMuted) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  muted = myMuted;
                });
              }
            });
          }

          return Column(
            children: [
              const SizedBox(height: 12),

              // ==================================================
              // STATUS
              // ==================================================

              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(16),
                  color:
                      Colors.deepPurple.shade900,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mic,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المنصة الصوتية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            myRole == 'speaker'
                                ? myMuted
                                    ? '🔇 أنت على المايك ومكتوم'
                                    : '🎙️ أنت تتحدث'
                                : '👂 أنت مستمع',
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      const Chip(
                        avatar: Icon(
                          Icons.star,
                          size: 17,
                        ),
                        label: Text('المالك'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // 5 MICROPHONES
              // ==================================================

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    '🎤 المايكات 5',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.all(12),
                  itemCount: 5,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder:
                      (context, index) {
                    final slot = index + 1;

                    Map<String, dynamic>?
                        participant;

                    for (final p
                        in participantMap.values) {
                      if (p['slot'] == slot &&
                          p['role'] ==
                              'speaker') {
                        participant = p;
                        break;
                      }
                    }

                    return micCard(
                      slot,
                      participant,
                    );
                  },
                ),
              ),

              // ==================================================
              // REQUESTS
              // ==================================================

              if (isOwner)
                SizedBox(
                  height: 150,
                  child: StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream: FirebaseFirestore
                        .instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('stage')
                        .doc('requests')
                        .collection('users')
                        .orderBy(
                          'createdAt',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      final requests =
                          snapshot.data?.docs ??
                              [];

                      if (requests.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد طلبات صعود حالياً',
                          ),
                        );
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        itemCount:
                            requests.length,
                        itemBuilder:
                            (context, index) {
                          return requestCard(
                            requests[index].data(),
                          );
                        },
                      );
                    },
                  ),
                ),

              // ==================================================
              // CONTROLS
              // ==================================================

              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (myRole == 'speaker')
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                toggleMute,
                            icon: Icon(
                              muted
                                  ? Icons.mic_off
                                  : Icons.mic,
                            ),
                            label: Text(
                              muted
                                  ? 'فتح المايك'
                                  : 'كتم',
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                requestMic,
                            icon: const Icon(
                              Icons.pan_tool,
                            ),
                            label: const Text(
                              'طلب المايك ✋',
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),

                      OutlinedButton.icon(
                        onPressed: leaveMic,
                        icon: const Icon(
                          Icons.logout,
                        ),
                        label: const Text(
                          'نزول',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    leaveVoice();
    super.dispose();
  }

  Future<void> leaveVoice() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final participantRef =
            FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .collection('stage')
                .doc('participants')
                .collection('users')
                .doc(user.uid);

        final doc =
            await participantRef.get();

        final data =
            doc.data() ?? {};

        final slot =
            data['slot'];

        if (slot != null) {
          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('stage')
              .doc('state')
              .set({
            'slot$slot':
                FieldValue.delete(),
          }, SetOptions(merge: true));
        }

        await participantRef.delete();
      } catch (_) {}
    }

    if (engineReady) {
      try {
        await _engine.leaveChannel();
        await _engine.release();
      } catch (_) {}
    }
  }
}

// ============================================================
// ROOM GAMES
// ============================================================

class RoomGamesPage extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomGamesPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  Future<void> createXO(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    final ref = await FirebaseFirestore.instance
        .collection('games')
        .add({
      'type': 'xo',
      'roomId': roomId,
      'status': 'pending',
      'creatorId': user.uid,
      'creatorNickname':
          profile['nickname'] ?? 'لاعب',
      'opponentId': null,
      'opponentNickname': null,
      'playerXId': user.uid,
      'playerXNickname':
          profile['nickname'] ?? 'لاعب',
      'playerOId': null,
      'playerONickname': null,
      'turn': user.uid,
      'board': List<String>.filled(9, ''),
      'winnerId': null,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineXOGamePage(
          gameId: ref.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ألعاب $roomName',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GameCard(
              icon: '❌⭕',
              title: 'XO أونلاين',
              subtitle:
                  'العب ضد لاعب داخل الغرفة',
              onTap: () => createXO(context),
            ),
            const SizedBox(height: 15),
            GameCard(
              icon: '🃏',
              title: 'UNO',
              subtitle: 'قريباً',
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'لعبة UNO قيد التطوير 🎴',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            GameCar
