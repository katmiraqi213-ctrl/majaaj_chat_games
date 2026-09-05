import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

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
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
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
// LOGIN / REGISTER
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

  bool isRegister = false;
  bool loading = false;
  bool obscurePassword = true;

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

    if (isRegister && nickname.isEmpty) {
      showMessage('اكتب الاسم المستعار');
      return;
    }

    if (isRegister && nickname.length < 3) {
      showMessage('الاسم المستعار لازم يكون 3 أحرف على الأقل');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (isRegister) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'nickname': nickname,
            'email': email,
            'points': 0,
            'level': 1,
            'avatarUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;

        showMessage('تم إنشاء الحساب بنجاح 🎉');
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'هذا الإيميل مستخدم مسبقاً';
          break;

        case 'invalid-email':
          message = 'الإيميل غير صحيح';
          break;

        case 'weak-password':
          message = 'كلمة المرور ضعيفة';
          break;

        case 'user-not-found':
          message = 'الحساب غير موجود';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'الإيميل أو كلمة المرور غير صحيحة';
          break;

        case 'network-request-failed':
          message = 'تأكد من اتصال الإنترنت';
          break;

        default:
          message = e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
      }

      showMessage(message);
    } catch (e) {
      showMessage('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    size: 80,
                    color: Colors.deepPurple,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'مزاج',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isRegister
                        ? 'أنشئ حسابك وابدأ اللعب 🎮'
                        : 'أهلاً بك في مزاج 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 35),

                  if (isRegister) ...[
                    TextField(
                      controller: nicknameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم المستعار',
                        hintText: 'مثال: KATM',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'الإيميل',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isRegister
                                  ? 'إنشاء حساب'
                                  : 'تسجيل الدخول',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
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
                              isRegister = !isRegister;
                            });
                          },
                    child: Text(
                      isRegister
                          ? 'عندي حساب مسبقاً - تسجيل الدخول'
                          : 'ما عندي حساب - إنشاء حساب',
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
  int currentIndex = 0;

  final pages = const [
    RoomsListPage(),
    GamesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'الغرف',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'الألعاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CURRENT USER PROFILE
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

  if (doc.exists) {
    return doc.data() ?? {};
  }

  return {
    'nickname': user.email?.split('@').first ?? 'لاعب',
    'email': user.email ?? '',
    'points': 0,
    'level': 1,
  };
}

// ============================================================
// ROOMS LIST
// ============================================================

class RoomsListPage extends StatelessWidget {
  const RoomsListPage({super.key});

  Future<void> createRoom(BuildContext context) async {
    final controller = TextEditingController();

    final roomName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إنشاء غرفة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم الغرفة',
              hintText: 'مثال: غرفة الأصدقاء',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (roomName == null || roomName.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    await FirebaseFirestore.instance.collection('rooms').add({
      'name': roomName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByNickname':
          profile['nickname'] ??
          user.email?.split('@').first ??
          'لاعب',
      'membersCount': 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomsRef = FirebaseFirestore.instance
        .collection('rooms')
        .orderBy(
          'createdAt',
          descending: true,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'غرف مزاج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createRoom(context),
        icon: const Icon(Icons.add),
        label: const Text('غرفة جديدة'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: roomsRef.snapshots(),
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
                'حدث خطأ: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final rooms = snapshot.data?.docs ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 70,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'ماكو غرف حالياً',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أنشئ أول غرفة وابدأ الدردشة 🎉',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              final data =
                  room.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.groups),
                  ),
                  title: Text(
                    data['name'] ?? 'غرفة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'أنشأها: ${data['createdByNickname'] ?? 'لاعب'}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          roomId: room.id,
                          roomName: data['name'] ?? 'غرفة',
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

  late final CollectionReference messagesRef;
  late final CollectionReference membersRef;
  late final CollectionReference gamesRef;

  String myNickname = 'لاعب';

  @override
  void initState() {
    super.initState();

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);

    messagesRef = roomRef.collection('messages');
    membersRef = roomRef.collection('members');
    gamesRef = roomRef.collection('games');

    joinRoom();
  }

  Future<void> joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    myNickname =
        profile['nickname'] ??
        user.email?.split('@').first ??
        'لاعب';

    await membersRef.doc(user.uid).set({
      'uid': user.uid,
      'nickname': myNickname,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .set(
      {
        'membersCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await membersRef.doc(user.uid).delete();

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set(
        {
          'membersCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    leaveRoom();
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final profile = await getCurrentUserProfile();

    final nickname =
        profile['nickname'] ??
        user.email?.split('@').first ??
        'لاعب';

    messageController.clear();

    await messagesRef.add({
      'text': text,
      'senderId': user.uid,
      'senderNickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // CREATE CHALLENGE
  // ==========================================================

  Future<void> challengePlayer(
    String opponentId,
    String opponentNickname,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (opponentId == user.uid) return;

    final profile = await getCurrentUserProfile();

    final nickname =
        profile['nickname'] ??
        user.email?.split('@').first ??
        'لاعب';

    final existing = await gamesRef
        .where('status', whereIn: [
          'pending',
          'playing',
        ])
        .get();

    for (final doc in existing.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final playerXId = data['playerXId'];
      final playerOId = data['playerOId'];

      if ((playerXId == user.uid ||
              playerOId == user.uid) &&
          (playerXId == opponentId ||
              playerOId == opponentId)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عندكم مباراة قائمة حالياً 🎮',
            ),
          ),
        );

        return;
      }
    }

    final gameRef = gamesRef.doc();

    await gameRef.set({
      'status': 'pending',
      'creatorId': user.uid,
      'creatorNickname': nickname,
      'opponentId': opponentId,
      'opponentNickname': opponentNickname,
      'playerXId': user.uid,
      'playerXNickname': nickname,
      'playerOId': opponentId,
      'playerONickname': opponentNickname,
      'turn': user.uid,
      'board': List<String>.filled(9, ''),
      'winnerId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineXOGamePage(
          roomId: widget.roomId,
          gameId: gameRef.id,
        ),
      ),
    );
  }

  // ==========================================================
  // MEMBERS
  // ==========================================================

  void showMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),

                const Text(
                  '👥 أعضاء الغرفة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Divider(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: membersRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final members =
                          snapshot.data?.docs ?? [];

                      if (members.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا يوجد أعضاء حالياً',
                          ),
                        );
                      }

                      final currentUser =
                          FirebaseAuth.instance.currentUser;

                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];

                          final data = member.data()
                              as Map<String, dynamic>;

                          final uid =
                              data['uid'] ?? member.id;

                          final nickname =
                              data['nickname'] ?? 'لاعب';

                          final isMe =
                              uid == currentUser?.uid;

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),

                            title: Text(
                              nickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              isMe
                                  ? 'أنت'
                                  : 'لاعب في الغرفة',
                            ),

                            trailing: isMe
                                ? const Chip(
                                    label: Text('أنت'),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);

                                      challengePlayer(
                                        uid,
                                        nickname,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.sports_esports,
                                    ),
                                    label: const Text(
                                      'تحدي',
                                    ),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // GAME BANNER
  // ==========================================================

  Widget gameBanner() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: gamesRef
          .orderBy(
            'createdAt',
            descending: true,
          )
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        QueryDocumentSnapshot? selected;

        for (final doc in docs) {
          final data =
              doc.data() as Map<String, dynamic>;

          final status = data['status'];

          final creatorId = data['creatorId'];
          final opponentId = data['opponentId'];

          if ((creatorId == user.uid ||
                  opponentId == user.uid) &&
              (status == 'pending' ||
                  status == 'playing' ||
                  status == 'finished' ||
                  status == 'draw')) {
            selected = doc;
            break;
          }
        }

        if (selected == null) {
          return const SizedBox();
        }

        final data =
            selected.data() as Map<String, dynamic>;

        final gameId = selected.id;
        final status = data['status'];

        final opponentName =
            data['creatorId'] == user.uid
                ? data['opponentNickname'] ?? 'لاعب'
                : data['creatorNickname'] ?? 'لاعب';

        if (status == 'pending' &&
            data['opponentId'] == user.uid) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              0,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.deepPurple.withOpacity(0.25),
              border: Border.all(
                color: Colors.deepPurple,
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.sports_esports,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎮 تحدي جديد',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '$opponentName يتحداك في XO',
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    await gamesRef.doc(gameId).update({
                      'status': 'playing',
                      'acceptedAt':
                          FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineXOGamePage(
                          roomId: widget.roomId,
                          gameId: gameId,
                        ),
                      ),
                    );
                  },
                  child: const Text('قبول'),
                ),
              ],
            ),
          );
        }

        if (status == 'pending') {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              0,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.orange.withOpacity(0.18),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بانتظار $opponentName لقبول التحدي...',
                  ),
                ),
              ],
            ),
          );
        }

        if (status == 'playing') {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              0,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.green.withOpacity(0.15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_esports,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'عندك مباراة XO ضد $opponentName',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineXOGamePage(
                          roomId: widget.roomId,
                          gameId: gameId,
                        ),
                      ),
                    );
                  },
                  child: const Text('دخول'),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesQuery = messagesRef.orderBy(
      'createdAt',
      descending: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(
            onPressed: showMembers,
            tooltip: 'أعضاء الغرفة',
            icon: const Icon(Icons.groups),
          ),
        ],
      ),

      body: Column(
        children: [
          gameBanner(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesQuery.snapshots(),
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
                      'حدث خطأ: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'ابدأ المحادثة 💬',
                      style: TextStyle(
                        fontSize: 18,
                      ),
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

                    final sender =
                        data['senderNickname'] ??
                            'لاعب';

                    final text =
                        data['text'] ?? '';

                    final currentUser =
                        FirebaseAuth.instance.currentUser;

                    final isMe =
                        data['senderId'] ==
                        currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 320,
                        ),
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.deepPurple
                              : Colors.grey.shade800,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(text),
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) =>
                          sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(25),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    radius: 25,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send),
                    ),
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
// GAMES PAGE
// ============================================================

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ألعاب مزاج 🎮',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameCard(
            icon: Icons.close,
            title: 'X و O',
            subtitle: 'لعبة XO أونلاين داخل الغرف',
            active: true,
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'ادخل غرفة وتحدى لاعب حتى تبدأ المباراة 🎮',
                  ),
                ),
              );
            },
          ),

          GameCard(
            icon: Icons.style,
            title: 'UNO',
            subtitle: 'قريباً',
            active: false,
          ),

          GameCard(
            icon: Icons.sports_handball,
            title: 'كيرم',
            subtitle: 'قريباً',
            active: false,
          ),

          GameCard(
            icon: Icons.casino,
            title: 'ألعاب أخرى',
            subtitle: 'راح نضيفها قريباً 🔥',
            active: false,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GAME CARD
// ============================================================

class GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: active
            ? const Icon(
                Icons.arrow_forward_ios,
              )
            : const Chip(
                label: Text('قريباً'),
              ),
        onTap: active ? onTap : null,
      ),
    );
  }
}

// ============================================================
// ONLINE XO
// ============================================================

class OnlineXOGamePage extends StatefulWidget {
  final String roomId;
  final String gameId;

  const OnlineXOGamePage({
    super.key,
    required this.roomId,
    required this.gameId,
  });

  @override
  State<OnlineXOGamePage> createState() =>
      _OnlineXOGamePageState();
}

class _OnlineXOGamePageState
    extends State<OnlineXOGamePage> {
  late final DocumentReference gameRef;

  @override
  void initState() {
    super.initState();

    gameRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('games')
        .doc(widget.gameId);
  }

  // ==========================================================
  // WINNER CHECK
  // ==========================================================

  String? checkWinner(
    List<String> board,
  ) {
    const patterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final pattern in patterns) {
      final a = pattern[0];
      final b = pattern[1];
      final c = pattern[2];

      if (board[a].isNotEmpty &&
          board[a] == board[b] &&
          board[a] == board[c]) {
        return board[a];
      }
    }

    return null;
  }

  // ==========================================================
  // PLAY MOVE
  // ==========================================================

  Future<void> playMove(
    int index,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final status = data['status'];

    if (status != 'playing') return;

    final turn = data['turn'];

    if (turn != user.uid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('مو دورك بعد ⏳'),
        ),
      );
      return;
    }

    final rawBoard =
        List<dynamic>.from(
      data['board'] ?? List.filled(9, ''),
    );

    final board = rawBoard
        .map((e) => e.toString())
        .toList();

    if (index < 0 ||
        index >= board.length ||
        board[index].isNotEmpty) {
      return;
    }

    final playerXId = data['playerXId'];
    final playerOId = data['playerOId'];

    String symbol;

    if (user.uid == playerXId) {
      symbol = 'X';
    } else if (user.uid == playerOId) {
      symbol = 'O';
    } else {
      return;
    }

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
      final snapshot =
          await transaction.get(gameRef);

      if (!snapshot.exists) return;

      final fresh =
          snapshot.data() as Map<String, dynamic>;

      if (fresh['status'] != 'playing') return;

      if (fresh['turn'] != user.uid) return;

      final freshBoard =
          List<dynamic>.from(
        fresh['board'] ??
            List.filled(9, ''),
      );

      if (freshBoard[index]
          .toString()
          .isNotEmpty) {
        return;
      }

      freshBoard[index] = symbol;

      final boardStrings = freshBoard
          .map((e) => e.toString())
          .toList();

      final winnerSymbol =
          checkWinner(boardStrings);

      final isDraw =
          winnerSymbol == null &&
          !boardStrings.contains('');

      if (winnerSymbol != null) {
        final winnerId =
            symbol == 'X'
                ? fresh['playerXId']
                : fresh['playerOId'];

        final winnerRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(winnerId);

        final winnerSnapshot =
            await transaction.get(winnerRef);

        int currentPoints = 0;

        if (winnerSnapshot.exists) {
          final winnerData =
              winnerSnapshot.data()
                  as Map<String, dynamic>?;

          currentPoints =
              (winnerData?['points'] ?? 0) as int;
        }

        final newPoints =
            currentPoints + 10;

        final newLevel =
            (newPoints ~/ 100) + 1;

        transaction.update(
          gameRef,
          {
            'board': boardStrings,
            'status': 'finished',
            'winnerId': winnerId,
            'winnerSymbol': winnerSymbol,
            'turn': '',
            'finishedAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          winnerRef,
          {
            'points': newPoints,
            'level': newLevel,
          },
          SetOptions(merge: true),
        );
      } else if (isDraw) {
        transaction.update(
          gameRef,
          {
            'board': boardStrings,
            'status': 'draw',
            'winnerId': '',
            'turn': '',
            'finishedAt':
                FieldValue.serverTimestamp(),
          },
        );
      } else {
        final nextPlayer =
            symbol == 'X'
                ? fresh['playerOId']
                : fresh['playerXId'];

        transaction.update(
          gameRef,
          {
            'board': boardStrings,
            'turn': nextPlayer,
          },
        );
      }
    });
  }

  // ==========================================================
  // REMATCH
  // ==========================================================

  Future<void> rematch(
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final newGameRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('games')
        .doc();

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
      final oldSnapshot =
          await transaction.get(gameRef);

      if (!oldSnapshot.exists) return;

      final oldData =
          oldSnapshot.data()
              as Map<String, dynamic>;

      final existingRematch =
          oldData['rematchGameId'];

      if (existingRematch != null &&
          existingRematch
              .toString()
              .isNotEmpty) {
        return;
      }

      transaction.update(
        gameRef,
        {
          'rematchGameId': newGameRef.id,
        },
      );

      transaction.set(
        newGameRef,
        {
          'status': 'playing',
          'creatorId':
              oldData['playerXId'],
          'creatorNickname':
              oldData['playerXNickname'],
          'opponentId':
              oldData['playerOId'],
          'opponentNickname':
              oldData['playerONickname'],
          'playerXId':
              oldData['playerXId'],
          'playerXNickname':
              oldData['playerXNickname'],
          'playerOId':
              oldData['playerOId'],
          'playerONickname':
              oldData['playerONickname'],
          'turn':
              oldData['playerXId'],
          'board':
              List<String>.filled(9, ''),
          'winnerId': '',
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );
    });

    final oldSnapshot = await gameRef.get();

    if (!oldSnapshot.exists) return;

    final oldData =
        oldSnapshot.data()
            as Map<String, dynamic>;

    final rematchId =
        oldData['rematchGameId'];

    if (rematchId == null ||
        rematchId.toString().isEmpty) {
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineXOGamePage(
          roomId: widget.roomId,
          gameId: rematchId,
        ),
      ),
    );
  }

  // ==========================================================
  // GAME RESULT
  // ==========================================================

  Widget resultWidget(
    Map<String, dynamic> data,
  ) {
    final status = data['status'];

    if (status == 'playing') {
      return const SizedBox();
    }

    if (status == 'draw') {
      return Column(
        children: [
          const Text(
            '🤝 تعادل',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () => rematch(data),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'لعب مرة ثانية',
            ),
          ),
        ],
      );
    }

    if (status == 'finished') {
      final winnerId =
          data['winnerId'] ?? '';

      final winnerName =
          winnerId == data['playerXId']
              ? data['playerXNickname'] ??
                  'اللاعب X'
              : data['playerONickname'] ??
                  'اللاعب O';

      final user =
          FirebaseAuth.instance.currentUser;

      final isMe =
          winnerId == user?.uid;

      return Column(
        children: [
          Text(
            isMe
                ? '🏆 فزت! +10 نقاط 🎉'
                : '😔 الفائز: $winnerName',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          const Text(
            'الفائز يحصل على 10 نقاط',
            style: TextStyle(
 
