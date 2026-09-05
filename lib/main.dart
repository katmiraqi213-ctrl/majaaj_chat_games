import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'firebase_options.dart';

/// ============================================================
/// AGORA
/// ============================================================

const String agoraAppId = '17efeb1c418a44e1b187a90eaa591023';

/// سيتم إضافة Token لاحقاً إذا كان مشروع Agora يحتاج Token.
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
            icon: const Icon(Icons.sports_esports),
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
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
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
                                data['nickname'] ?? 'لاعب',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => sendMessage(),
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

  String _agoraRole = 'listener';
  bool _agoraMuted = true;
  bool _syncingAgora = false;

  @override
  void initState() {
    super.initState();
    initializeVoice();
  }

  // ==========================================================
  // FIRESTORE REFERENCES
  // ==========================================================

  DocumentReference<Map<String, dynamic>> participantRef(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('participants')
        .collection('users')
        .doc(uid);
  }

  DocumentReference<Map<String, dynamic>> get stageRef {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('state');
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> initializeVoice() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final profile = await getCurrentUserProfile();

      nickname = profile['nickname'] ?? 'لاعب';

      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .get();

      final roomData = roomDoc.data() ?? {};

      isOwner = roomData['ownerId'] == user.uid;

      await createVoiceEngine();

      if (!engineReady) return;

      final myRef = participantRef(user.uid);
      final myDoc = await myRef.get();

      final existingData = myDoc.data();

      String role = existingData?['role'] ?? 'listener';
      dynamic existingSlot = existingData?['slot'];
      bool existingMuted = existingData?['muted'] ?? true;

      // --------------------------------------------------------
      // إذا كان المستخدم موجود مسبقاً بالمنصة، نحافظ على وضعه.
      // --------------------------------------------------------

      if (existingData == null) {
        if (isOwner) {
          final stateDoc = await stageRef.get();
          final state = stateDoc.data() ?? {};

          final slot1Owner = state['slot1'];

          if (slot1Owner == null ||
              slot1Owner == user.uid) {
            role = 'speaker';
            existingSlot = 1;
            existingMuted = true;

            await stageRef.set({
              'slot1': user.uid,
            }, SetOptions(merge: true));
          } else {
            role = 'listener';
            existingSlot = null;
            existingMuted = true;
          }
        }
      }

      await myRef.set({
        'uid': user.uid,
        'nickname': nickname,
        'role': role,
        'slot': existingSlot,
        'muted': existingMuted,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      muted = existingMuted;

      await joinAgoraChannel();

      if (role == 'speaker') {
        await applyAgoraRole(
          role: 'speaker',
          shouldMute: existingMuted,
        );
      }
    } catch (e) {
      debugPrint('Voice initialize error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تشغيل المنصة الصوتية: $e',
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // AGORA ENGINE
  // ==========================================================

  Future<void> createVoiceEngine() async {
    if (agoraAppId.isEmpty) {
      engineReady = false;
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
        onJoinChannelSuccess: (
          connection,
          elapsed,
        ) {
          debugPrint(
            'Agora joined channel: ${connection.channelId}',
          );
        },
        onUserJoined: (
          connection,
          remoteUid,
          elapsed,
        ) {
          debugPrint(
            'Agora remote user joined: $remoteUid',
          );
        },
        onUserOffline: (
          connection,
          remoteUid,
          reason,
        ) {
          debugPrint(
            'Agora remote user left: $remoteUid',
          );
        },
        onClientRoleChanged: (
          connection,
          oldRole,
          newRole,
          newRoleOptions,
        ) {
          debugPrint(
            'Agora role changed: $oldRole -> $newRole',
          );
        },
      ),
    );

    await _engine.enableAudio();

    engineReady = true;
  }

  // ==========================================================
  // JOIN AGORA
  // ==========================================================

  Future<void> joinAgoraChannel() async {
    if (!engineReady || joinedVoice) return;

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
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في الاتصال بالصوت: $e',
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // APPLY AGORA ROLE
  // ==========================================================

  Future<void> applyAgoraRole({
    required String role,
    required bool shouldMute,
  }) async {
    if (!engineReady || !joinedVoice) return;

    if (_syncingAgora) return;

    if (_agoraRole == role &&
        _agoraMuted == shouldMute) {
      return;
    }

    _syncingAgora = true;

    try {
      if (role == 'speaker') {
        // يتحول من مستمع إلى متحدث.
        await _engine.setClientRole(
          role: ClientRoleType.clientRoleBroadcaster,
        );

        await _engine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            clientRoleType:
                ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: false,
          ),
        );

        await _engine.muteLocalAudioStream(
          shouldMute,
        );
      } else {
        // يرجع مستمع.
        await _engine.muteLocalAudioStream(true);

        await _engine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            clientRoleType:
                ClientRoleType.clientRoleAudience,
            publishMicrophoneTrack: false,
            autoSubscribeAudio: true,
            autoSubscribeVideo: false,
          ),
        );

        await _engine.setClientRole(
          role: ClientRoleType.clientRoleAudience,
        );
      }

      _agoraRole = role;
      _agoraMuted = shouldMute;
    } catch (e) {
      debugPrint(
        'Agora role sync error: $e',
      );
    } finally {
      _syncingAgora = false;
    }
  }

  // ==========================================================
  // BECOME SPEAKER
  // ==========================================================

  Future<void> becomeSpeaker(
    String uid,
    int slot,
  ) async {
    if (!isOwner) return;

    final targetRef = participantRef(uid);

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final stageSnapshot =
            await transaction.get(stageRef);

        final stageData =
            stageSnapshot.data() ?? {};

        if (stageData['slot$slot'] != null) {
          throw Exception(
            'هذا المايك مستخدم',
          );
        }

        final targetSnapshot =
            await transaction.get(targetRef);

        if (!targetSnapshot.exists) {
          throw Exception(
            'اللاعب غير موجود بالمنصة',
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
          targetRef,
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
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================
  // REQUEST MIC
  // ==========================================================

  Future<void> requestMic() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final me = await participantRef(user.uid).get();
    final data = me.data() ?? {};

    if (data['role'] == 'speaker') {
      return;
    }

    final requestRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('requests')
        .collection('users')
        .doc(user.uid);

    await requestRef.set({
      'uid': user.uid,
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
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

  // ==========================================================
  // LEAVE MIC
  // ==========================================================

  Future<void> leaveMic() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final ref = participantRef(user.uid);

    final participant = await ref.get();
    final data = participant.data() ?? {};

    final slot = data['slot'];

    if (slot != null) {
      await stageRef.set({
        'slot$slot': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    await ref.set({
      'role': 'listener',
      'slot': null,
      'muted': true,
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('stage')
        .doc('requests')
        .collection('users')
        .doc(user.uid)
        .delete()
        .catchError((_) {});

    await applyAgoraRole(
      role: 'listener',
      shouldMute: true,
    );

    if (mounted) {
      setState(() {
        muted = true;
      });
    }
  }

  // ==========================================================
  // MUTE / UNMUTE LOCAL
  // ==========================================================

  Future<void> toggleMute() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final ref = participantRef(user.uid);

    final doc = await ref.get();
    final data = doc.data() ?? {};

    if (data['role'] != 'speaker') {
      return;
    }

    final newMuted = !muted;

    await ref.set({
      'muted': newMuted,
    }, SetOptions(merge: true));

    if (engineReady && joinedVoice) {
      await _engine.muteLocalAudioStream(
        newMuted,
      );
    }

    _agoraMuted = newMuted;

    if (mounted) {
      setState(() {
        muted = newMuted;
      });
    }
  }

  // ==========================================================
  // DEMOTE SPEAKER
  // ==========================================================

  Future<void> demoteSpeaker(
    String uid,
    int slot,
  ) async {
    if (!isOwner) return;

    final targetRef = participantRef(uid);

    await targetRef.set({
      'role': 'listener',
      'slot': null,
      'muted': true,
    }, SetOptions(merge: true));

    await stageRef.set({
      'slot$slot': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // ==========================================================
  // MUTE SPEAKER
  // ==========================================================

  Future<void> muteSpeaker(
    String uid,
    bool value,
  ) async {
    if (!isOwner) return;

    await participantRef(uid).set({
      'muted': value,
    }, SetOptions(merge: true));
  }

  // ==========================================================
  // MIC CARD
  // ==========================================================

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
            uid !=
                FirebaseAuth.instance.currentUser?.uid) {
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
            mainAxisAlignment:
                MainAxisAlignment.center,
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

  // ==========================================================
  // SPEAKER MENU
  // ==========================================================

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

  // ==========================================================
  // REQUEST CARD
  // ==========================================================

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

  // ==========================================================
  // FIND FREE SLOT
  // ==========================================================

  Future<int?> findFreeSlot() async {
    final doc = await stageRef.get();

    final data = doc.data() ?? {};

    for (final slot in micSlots) {
      if (data['slot$slot'] == null) {
        return slot;
      }
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
        builder: (
          context,
          participantSnapshot,
        ) {
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

          // ----------------------------------------------------
          // مزامنة حالة المستخدم مع Agora
          // ----------------------------------------------------

          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (!mounted) return;

              if (muted != myMuted) {
                setState(() {
                  muted = myMuted;
                });
              }

              if (joinedVoice) {
                applyAgoraRole(
                  role: myRole,
                  shouldMute: myMuted,
                );
              }
            },
          );

          return Column(
            children: [
              const SizedBox(height: 12),

              // =================================================
              // STATUS
              // =================================================

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

              // =================================================
              // FIVE MICROPHONES
              // =================================================

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

              // =================================================
              // REQUESTS
              // =================================================

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
                    builder: (
                      context,
                      snapshot,
                    ) {
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

              // =================================================
              // CONTROLS
              // =================================================

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
                                  ? 'فتح المايك 🎙️'
                                  : 'كتم المايك 🔇',
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: requestMic,
                            icon: const Icon(
                              Icons.pan_tool,
                            ),
                            label: const Text(
                              'طلب الصعود للمايك ✋',
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (myRole == 'speaker')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: leaveMic,
                            icon: const Icon(
                              Icons.arrow_downward,
                            ),
                            label: const Text(
                              'نزول من المايك',
                            ),
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
    if (engineReady) {
      _engine.leaveChannel();
      _engine.release();
    }

    super.dispose();
  }
}

// ============================================================
// GAMES
// ============================================================

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 الألعاب'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.close,
                size: 35,
              ),
              title: const Text(
                'XO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'لعبة X و O للاعبين',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const XOPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.style,
                size: 35,
              ),
              title: const Text(
                'UNO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'قريباً 🔥',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.circle,
                size: 35,
              ),
              title: const Text(
                'كيرم',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'قريباً 🔥',
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎮 $roomName'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.close,
                size: 35,
              ),
              title: const Text(
                'XO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'لعب XO داخل الغرفة',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => XOPage(
                      roomId: roomId,
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.style,
                size: 35,
              ),
              title: const Text('UNO'),
              subtitle: const Text('قريباً 🔥'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.circle,
                size: 35,
              ),
              title: const Text('كيرم'),
              subtitle: const Text('قريباً 🔥'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 حسابي'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data ?? {};

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 45,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    data['nickname'] ?? 'لاعب',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⭐ النقاط: ${data['points'] ?? 0}',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '🏆 المستوى: ${data['level'] ?? 1}',
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance
                          .signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'تسجيل الخروج',
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// XO GAME
// ============================================================

class XOPage extends StatefulWidget {
  final String? roomId;

  const XOPage({
    super.key,
    this.roomId,
  });

  @override
  State<XOPage> createState() => _XOPageState();
}

class _XOPageState extends State<XOPage> {
  List<String> board =
      List<String>.filled(9, '');

  String currentPlayer = 'X';
  String? winner;
  bool gameOver = false;

  void play(int index) {
    if (board[index].isNotEmpty ||
        gameOver) {
      return;
    }

    setState(() {
      board[index] = currentPlayer;

      final result = checkWinner();

      if (result != null) {
        winner = result;
        gameOver = true;
      } else if (!board.contains('')) {
        winner = 'تعادل';
        gameOver = true;
      } else {
        currentPlayer =
            currentPlayer == 'X' ? 'O' : 'X';
      }
    });
  }

  String? checkWinner() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in lines) {
      final a = line[0];
      final b = line[1];
      final c = line[2];

      if (board[a].isNotEmpty &&
          board[a] == board[b] &&
          board[a] == board[c]) {
        return board[a];
      }
    }

    return null;
  }

  void resetGame() {
    setState(() {
      board = List<String>.filled(9, '');
      currentPlayer = 'X';
      winner = null;
      gameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('❌⭕ XO'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          Text(
            winner == null
                ? 'دور اللاعب: $currentPlayer'
                : winner == 'تعادل'
                    ? '🤝 تعادل'
                    : '🏆 الفائز: $winner',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: Center(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(25),
                itemCount: 9,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => play(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(15),
                        color:
                            Colors.grey.shade800,
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                board[index] == 'X'
                                    ? Colors.blue
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'لعبة جديدة',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
 
