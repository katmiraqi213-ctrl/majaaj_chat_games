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
              constraints: const BoxConstraints(maxWidth: 450),
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
                              isRegister ? 'إنشاء حساب' : 'تسجيل الدخول',
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
// PROFILE HELPER
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
// ROOMS
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
              onPressed: () => Navigator.pop(context),
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
          profile['nickname'] ?? user.email?.split('@').first ?? 'لاعب',
      'membersCount': 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomsRef = FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('createdAt', descending: true);

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
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                  Text('أنشئ أول غرفة وابدأ الدردشة 🎉'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final data = room.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
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
                  trailing: const Icon(Icons.arrow_forward_ios),
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

  @override
  void initState() {
    super.initState();

    messagesRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages');
  }

  @override
  void dispose() {
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
        profile['nickname'] ?? user.email?.split('@').first ?? 'لاعب';

    messageController.clear();

    await messagesRef.add({
      'text': text,
      'senderId': user.uid,
      'senderNickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                final messages = snapshot.data?.docs ?? [];

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
                        messages[index].data() as Map<String, dynamic>;

                    final sender =
                        data['senderNickname'] ?? 'لاعب';

                    final text = data['text'] ?? '';

                    final currentUser =
                        FirebaseAuth.instance.currentUser;

                    final isMe =
                        data['senderId'] == currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 320,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.deepPurple
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
// GAMES
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
            subtitle: 'لعبة XO',
            active: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const XOGame(),
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
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
            ? const Icon(Icons.arrow_forward_ios)
            : const Chip(
                label: Text('قريباً'),
              ),
        onTap: active ? onTap : null,
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data ?? {};

          final nickname =
              data['nickname'] ?? user.email?.split('@').first ?? 'لاعب';

          final points = data['points'] ?? 0;
          final level = data['level'] ?? 1;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              const CircleAvatar(
                radius: 55,
                child: Icon(
                  Icons.person,
                  size: 55,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Center(
                child: Text(
                  user.email ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.star,
                      title: 'النقاط',
                      value: '$points',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.emoji_events,
                      title: 'المستوى',
                      value: '$level',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('الاسم المستعار'),
                  subtitle: Text(nickname),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('الإيميل'),
                  subtitle: Text(user.email ?? ''),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOCAL XO
// ============================================================

class XOGame extends StatefulWidget {
  const XOGame({super.key});

  @override
  State<XOGame> createState() => _XOGameState();
}

class _XOGameState extends State<XOGame> {
  List<String> board = List.filled(9, '');

  String currentPlayer = 'X';

  String result = '';

  void play(int index) {
    if (board[index].isNotEmpty || result.isNotEmpty) {
      return;
    }

    setState(() {
      board[index] = currentPlayer;
    });

    checkWinner();

    if (result.isEmpty) {
      setState(() {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
      });
    }
  }

  void checkWinner() {
    const winningPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final pattern in winningPatterns) {
      final a = pattern[0];
      final b = pattern[1];
      final c = pattern[2];

      if (board[a].isNotEmpty &&
          board[a] == board[b] &&
          board[a] == board[c]) {
        setState(() {
          result = 'الفائز: ${board[a]} 🎉';
        });
        return;
      }
    }

    if (!board.contains('')) {
      setState(() {
        result = 'تعادل 🤝';
      });
    }
  }

  void resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X و O'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (result.isEmpty)
              Text(
                'دور اللاعب: $currentPlayer',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                result,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 25),

            SizedBox(
              width: 330,
              height: 330,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => play(index),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: const TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('لعبة جديدة'),
            ),
          ],
        ),
      ),
    );
  }
}
