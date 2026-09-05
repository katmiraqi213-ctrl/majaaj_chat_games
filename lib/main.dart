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
        credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
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
      'ownerNickname':
          profile['nickname'] ?? 'لاعب',
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
                  rooms[index].data()
                      as Map<String, dynamic>;

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
                          roomName:
                              room['name'] ?? 'غرفة',
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
        currentNickname =
            data['nickname'] ?? 'لاعب';
      });
    }
  }

  Future<void> joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('members')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'nickname': currentNickname ?? 'لاعب',
      'joinedAt': FieldValue.serverTimestamp(),
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
      'nickname':
          profile['nickname'] ?? 'لاعب',
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
                    child:
                        CircularProgressIndicator(),
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
                  padding:
                      const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder:
                      (context, index) {
                    final data =
                        messages[index].data()
                            as Map<String, dynamic>;

                    final user =
                        FirebaseAuth.instance
                            .currentUser;

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
                              BorderRadius.circular(
                            14,
                          ),
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
                      controller:
                          messageController,
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
                    icon:
                        const Icon(Icons.send),
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
              subtitle:
                  'قريباً',
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

            GameCard(
              icon: '🎱',
              title: 'كيرم',
              subtitle:
                  'قريباً',
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'لعبة الكيرم قيد التطوير 🎱',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
          'الألعاب 🎮',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameCard(
            icon: '❌⭕',
            title: 'XO أونلاين',
            subtitle:
                'اللعب يكون من داخل الغرف',
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'ادخل إلى غرفة ثم اختر XO',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 15),

          GameCard(
            icon: '🃏',
            title: 'UNO',
            subtitle: 'قريباً',
            onTap: () {},
          ),

          const SizedBox(height: 15),

          GameCard(
            icon: '🎱',
            title: 'كيرم',
            subtitle: 'قريباً',
            onTap: () {},
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
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(
                  fontSize: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ONLINE XO
// ============================================================

class OnlineXOGamePage extends StatefulWidget {
  final String gameId;

  const OnlineXOGamePage({
    super.key,
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
        .collection('games')
        .doc(widget.gameId);
  }

  // ==========================================================
  // CHECK WINNER
  // ==========================================================

  String? checkWinner(List<String> board) {
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
      final a = board[line[0]];
      final b = board[line[1]];
      final c = board[line[2]];

      if (a.isNotEmpty &&
          a == b &&
          b == c) {
        return a;
      }
    }

    if (!board.contains('')) {
      return 'draw';
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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (data['status'] != 'playing') {
      return;
    }

    if (data['turn'] != user.uid) {
      return;
    }

    final board = List<String>.from(
      data['board'] ??
          List<String>.filled(9, ''),
    );

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

    board[index] = symbol;

    final winner = checkWinner(board);

    if (winner == 'X' ||
        winner == 'O') {
      final winnerId =
          winner == 'X'
              ? playerXId
              : playerOId;

      await gameRef.update({
        'board': board,
        'status': 'finished',
        'winnerId': winnerId,
      });

      await addWinnerPoints(winnerId);

      return;
    }

    if (winner == 'draw') {
      await gameRef.update({
        'board': board,
        'status': 'draw',
      });

      return;
    }

    final nextTurn =
        user.uid == playerXId
            ? playerOId
            : playerXId;

    await gameRef.update({
      'board': board,
      'turn': nextTurn,
    });
  }

  // ==========================================================
  // ADD POINTS
  // ==========================================================

  Future<void> addWinnerPoints(
    String? winnerId,
  ) async {
    if (winnerId == null ||
        winnerId.isEmpty) {
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(winnerId);

    await FirebaseFirestore.instance
        .runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(ref);

        final data =
            snapshot.data() ?? {};

        final oldPoints =
            (data['points'] ?? 0) as num;

        final newPoints =
            oldPoints.toInt() + 10;

        final newLevel =
            (newPoints ~/ 100) + 1;

        transaction.set(
          ref,
          {
            'points': newPoints,
            'level': newLevel,
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );
  }

  // ==========================================================
  // REMATCH
  // ==========================================================

  Future<void> rematch(
    Map<String, dynamic> data,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final playerXId = data['playerXId'];
    final playerOId = data['playerOId'];

    final opponentId =
        user.uid == playerXId
            ? playerOId
            : playerXId;

    if (opponentId == null) {
      return;
    }

    final newGame = await FirebaseFirestore
        .instance
        .collection('games')
        .add({
      'type': 'xo',
      'roomId': data['roomId'],
      'status': 'playing',
      'creatorId': playerXId,
      'creatorNickname':
          data['playerXNickname'] ??
              'اللاعب X',
      'opponentId': playerOId,
      'opponentNickname':
          data['playerONickname'] ??
              'اللاعب O',
      'playerXId': playerXId,
      'playerXNickname':
          data['playerXNickname'] ??
              'اللاعب X',
      'playerOId': playerOId,
      'playerONickname':
          data['playerONickname'] ??
              'اللاعب O',
      'turn': playerXId,
      'board': List<String>.filled(9, ''),
      'winnerId': null,
      'createdAt':
          FieldValue.serverTimestamp(),
      'rematchGameId': widget.gameId,
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineXOGamePage(
          gameId: newGame.id,
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

    if (status == 'pending') {
      return Column(
        children: [
          const Text(
            '⏳ بانتظار لاعب',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'افتح الغرفة وخلي لاعب ثاني ينضم للمباراة',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

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
              fontSize: 17,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: () =>
                rematch(data),
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'لعب مرة ثانية',
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  // ==========================================================
  // BUILD XO GAME
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'XO أونلاين 🎮',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: gameRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'المباراة غير موجودة',
                style:
                    TextStyle(fontSize: 18),
              ),
            );
          }

          final data =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          final board =
              List<String>.from(
            (data['board'] ??
                    List<String>.filled(
                      9,
                      '',
                    ))
                .map(
              (e) => e.toString(),
            ),
          );

          final user =
              FirebaseAuth.instance
                  .currentUser;

          final playerXId =
              data['playerXId'];

          final playerOId =
              data['playerOId'];

          final turn =
              data['turn'];

          final status =
              data['status'];

          final mySymbol =
              user?.uid == playerXId
                  ? 'X'
                  : user?.uid ==
                          playerOId
                      ? 'O'
                      : '';

          final turnName =
              turn == playerXId
                  ? data[
                          'playerXNickname'] ??
                      'اللاعب X'
                  : turn == playerOId
                      ? data[
                              'playerONickname'] ??
                          'اللاعب O'
                      : '';

          return SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${data['playerXNickname'] ?? 'X'}  ❌  ضد  ⭕  ${data['playerONickname'] ?? 'بانتظار لاعب'}',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (status == 'playing')
                    Text(
                      turn == user?.uid
                          ? '🎯 دورك'
                          : '⏳ دور $turnName',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 20),

                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder:
                        (context, index) {
                      final value =
                          board[index];

                      return InkWell(
                        onTap:
                            status ==
                                        'playing' &&
                                    turn ==
                                        user?.uid &&
                                    value.isEmpty &&
                                    mySymbol
                                        .isNotEmpty
                                ? () => playMove(
                                      index,
                                      data,
                                    )
                                : null,
                        borderRadius:
                            BorderRadius
                                .circular(16),
                        child: Container(
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                            color: Colors
                                .grey
                                .shade900,
                            border:
                                Border.all(
                              color: Colors
                                  .deepPurple,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    value == 'X'
                                        ? Colors
                                            .redAccent
                                        : Colors
                                            .blueAccent,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  resultWidget(data),
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
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حسابي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<
          Map<String, dynamic>>(
        future: getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final data =
              snapshot.data ?? {};

          final nickname =
              data['nickname'] ??
                  user?.email
                      ?.split('@')
                      .first ??
                  'لاعب';

          final email =
              data['email'] ??
                  user?.email ??
                  '';

          final points =
              data['points'] ?? 0;

          final level =
              data['level'] ?? 1;

          return ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 45,
                child: Icon(
                  Icons.person,
                  size: 50,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  nickname.toString(),
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Center(
                child: Text(
                  email.toString(),
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(18),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 32,
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              points
                                  .toString(),
                              style:
                                  const TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const Text(
                              'النقاط',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(18),
                        child: Column(
                          children: [
                            const Icon(
                              Icons
                                  .workspace_premium,
                              size: 32,
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              level
                                  .toString(),
                              style:
                                  const TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const Text(
                              'المستوى',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  leading:
                      const Icon(
                    Icons.logout,
                  ),
                  title:
                      const Text(
                    'تسجيل الخروج',
                  ),
                  onTap: () async {
                    await FirebaseAuth
                        .instance
                        .signOut();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
