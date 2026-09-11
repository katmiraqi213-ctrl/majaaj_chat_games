import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';

const String agoraAppId = 'YOUR_AGORA_APP_ID';
const String agoraToken = 'YOUR_AGORA_TOKEN';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MazaajApp());
}

class MazaajApp extends StatelessWidget {
  const MazaajApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزاج',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF090912),
        cardTheme: CardTheme(
          color: const Color(0xFF151522),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151522),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
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
          return const SplashPage();
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MazaajLogo(),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _MazaajLogo extends StatelessWidget {
  const _MazaajLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 25,
            spreadRadius: 2,
            color: Color(0x558B5CF6),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'مزاج',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
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

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('اكتب الإيميل وكلمة المرور');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'فشل تسجيل الدخول');
    } catch (e) {
      showMessage('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
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
                const _MazaajLogo(),
                const SizedBox(height: 25),
                const Text(
                  'أهلاً بك في مزاج',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ادخل لحسابك واستمتع بالرومات والألعاب',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 35),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'الإيميل',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => obscure = !obscure);
                      },
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text('إنشاء حساب جديد'),
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
// REGISTER
// ============================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (nickname.isEmpty || email.isEmpty || password.length < 6) {
      showMessage('تأكد من الاسم والإيميل وكلمة المرور 6 أحرف على الأقل');
      return;
    }

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(nickname);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'nickname': nickname,
          'email': email,
          'points': 0,
          'coins': 0,
          'level': 1,
          'avatarBase64': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'فشل إنشاء الحساب');
    } catch (e) {
      showMessage('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const _MazaajLogo(),
              const SizedBox(height: 25),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم المستعار',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'الإيميل',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => obscure = !obscure);
                    },
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'إنشاء الحساب',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
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
  int index = 0;

  final pages = const [
    RoomsPage(),
    GamesPage(),
    WalletPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'الرومات',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'الألعاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
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
// ROOMS
// ============================================================

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رومات مزاج',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'إنشاء روم',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateRoomPage(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline,
              title: 'حدث خطأ',
              subtitle: 'تأكد من إعداد Firestore',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'ماكو رومات حالياً',
              subtitle: 'اضغط + وسوّي أول روم',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return _RoomCard(
                data: data,
                roomId: docs[index].id,
              );
            },
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String roomId;

  const _RoomCard({
    required this.data,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${data['name'] ?? 'روم'}';
    final description = '${data['description'] ?? 'روم مزاج'}';
    final members = data['membersCount'] ?? 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomPage(
                roomId: roomId,
                data: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.meeting_room,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('$members'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CREATE ROOM
// ============================================================

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      showMessage('اكتب اسم الروم');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() => loading = true);

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final nickname =
          '${profile.data()?['nickname'] ?? user.displayName ?? 'لاعب'}';

      await FirebaseFirestore.instance.collection('rooms').add({
        'name': name,
        'description': description,
        'ownerId': user.uid,
        'ownerName': nickname,
        'membersCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage('تعذر إنشاء الروم: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء روم'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الروم',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف الروم',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : createRoom,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('إنشاء الروم'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROOM PAGE
// ============================================================

class RoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> data;

  const RoomPage({
    super.key,
    required this.roomId,
    required this.data,
  });

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final messageController = TextEditingController();
  final picker = ImagePicker();
  final scrollController = ScrollController();

  bool imageUploading = false;

  CollectionReference<Map<String, dynamic>> get messagesRef =>
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages');

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 'لاعب';
    }

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return '${profile.data()?['nickname'] ?? user.displayName ?? 'لاعب'}';
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final name = await getUserName();

    await messagesRef.add({
      'type': 'text',
      'text': text,
      'userId': user.uid,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    messageController.clear();
    scrollMessages();
  }

  Future<void> pickAndSendImage() async {
    if (imageUploading) {
      return;
    }

    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (file == null) {
        return;
      }

      setState(() => imageUploading = true);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > 500 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'الصورة كبيرة. اختار صورة أصغر من 500KB.',
              ),
            ),
          );
        }
        return;
      }

      final imageBase64 = base64Encode(bytes);
      final name = await getUserName();

      await messagesRef.add({
        'type': 'image',
        'imageBase64': imageBase64,
        'userId': user.uid,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      scrollMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الصورة: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => imageUploading = false);
      }
    }
  }

  void scrollMessages() {
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (!scrollController.hasClients) return;

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  Widget buildBase64Image(Map<String, dynamic> message) {
    final encoded = message['imageBase64'];

    if (encoded is! String || encoded.isEmpty) {
      return const SizedBox(
        height: 120,
        width: 280,
        child: Center(
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.memory(
          base64Decode(encoded),
          width: 280,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            );
          },
        ),
      );
    } catch (_) {
      return const SizedBox(
        height: 120,
        width: 280,
        child: Center(
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomName = '${widget.data['name'] ?? 'الروم'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roomName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'الصوت',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceRoomPage(
                    channelName: 'room_${widget.roomId}',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.mic_none),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesRef
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'الروم فارغ',
                    subtitle: 'اكتب أول رسالة وابدأ الدردشة',
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    return _MessageBubble(
                      data: data,
                      imageBuilder: buildBase64Image,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                8,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF10101A),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        imageUploading ? null : pickAndSendImage,
                    icon: imageUploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.photo_outlined,
                          ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
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
// MESSAGE
// ============================================================

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final Widget Function(Map<String, dynamic>) imageBuilder;

  const _MessageBubble({
    required this.data,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final type = '${data['type'] ?? 'text'}';
    final name = '${data['name'] ?? 'لاعب'}';
    final text = '${data['text'] ?? ''}';

    if (type == 'image') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            imageBuilder(data),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF171725),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFB78CFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

// ============================================================
// VOICE / AGORA
// ============================================================

class VoiceRoomPage extends StatefulWidget {
  final String channelName;

  const VoiceRoomPage({
    super.key,
    required this.channelName,
  });

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {
  RtcEngine? engine;

  bool joined = false;
  bool muted = false;
  bool speaker = true;

  final Set<int> remoteUsers = {};

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    if (agoraAppId == 'YOUR_AGORA_APP_ID') {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    await Permission.microphone.request();

    final e = createAgoraRtcEngine();

    engine = e;

    await e.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
      ),
    );

    e.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (
          RtcConnection connection,
          int elapsed,
        ) {
          if (!mounted) return;

          setState(() {
            joined = true;
          });
        },
        onUserJoined: (
          RtcConnection connection,
          int remoteUid,
          int elapsed,
        ) {
          if (!mounted) return;

          setState(() {
            remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          if (!mounted) return;

          setState(() {
            remoteUsers.remove(remoteUid);
          });
        },
      ),
    );

    await e.enableAudio();

    await e.setEnableSpeakerphone(true);

    await e.joinChannel(
      token: agoraToken,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> toggleMute() async {
    final e = engine;

    if (e == null) return;

    muted = !muted;

    await e.muteLocalAudioStream(muted);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleSpeaker() async {
    final e = engine;

    if (e == null) return;

    speaker = !speaker;

    await e.setEnableSpeakerphone(speaker);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> leave() async {
    final e = engine;

    if (e != null) {
      await e.leaveChannel();
      await e.release();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    engine?.leaveChannel();
    engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notConfigured =
        agoraAppId == 'YOUR_AGORA_APP_ID';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الغرفة الصوتية'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(
            Icons.mic,
            size: 80,
          ),
          const SizedBox(height: 15),
          Text(
            widget.channelName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          if (notConfigured)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'الصوت جاهز بالكود، لكن لازم تحط Agora App ID و Token.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                ),
              ),
            )
          else ...[
            Text(
              joined ? 'متصل بالصوت' : 'جاري الاتصال...',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'المستخدمون: ${remoteUsers.length + (joined ? 1 : 0)}',
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: toggleMute,
                  icon: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                  ),
                ),
                const SizedBox(width: 15),
                IconButton.filled(
                  onPressed: toggleSpeaker,
                  icon: Icon(
                    speaker
                        ? Icons.volume_up
                        : Icons.volume_off,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.tonal(
                onPressed: leave,
                child: const Text('خروج من الصوت'),
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
          'الألعاب',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(
            title: 'ألعاب مزاج',
            subtitle: 'اللعب أونلاين • نقاط • ترتيب',
          ),
          const SizedBox(height: 10),
          _GameCard(
            icon: Icons.grid_4x4_rounded,
            title: 'لودو',
            subtitle: '2 أو 4 لاعبين',
            badge: 'قريباً',
          ),
          _GameCard(
            icon: Icons.style_rounded,
            title: 'أونو',
            subtitle: 'بطاقات وتحديات',
            badge: 'قريباً',
          ),
          _GameCard(
            icon: Icons.radio_button_checked_rounded,
            title: 'كيرم',
            subtitle: 'تنافس أونلاين',
            badge: 'قريباً',
          ),
          _GameCard(
            icon: Icons.close_rounded,
            title: 'XO',
            subtitle: '1 ضد 1',
            badge: 'قريباً',
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(.15),
          ),
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(badge),
        ),
      ),
    );
  }
}

// ============================================================
// WALLET
// ============================================================

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المحفظة',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final coins = data['coins'] ?? 0;
          final points = data['points'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 55,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'الرصيد',
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'النقاط: $points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TopUpPage(),
                      ),
                    );
                  },
                  child: const Text('شحن الرصيد'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// TOP UP
// ============================================================

class TopUpPage extends StatelessWidget {
  const TopUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شحن الرصيد'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(
            title: 'طرق الشحن',
            subtitle: 'اختار الطريقة المناسبة لاحقاً',
          ),
          _MenuTile(
            icon: Icons.credit_card,
            title: 'بطاقة ماستر كارد',
            subtitle: 'قريباً',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.phone_android,
            title: 'رصيد الهاتف',
            subtitle: 'قريباً',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.payment,
            title: 'طرق دفع أخرى',
            subtitle: 'قريباً',
            onTap: () {},
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

  Future<Map<String, dynamic>> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {};
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حسابي',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getProfile(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          final nickname =
              '${data['nickname'] ?? user.displayName ?? 'لاعب'}';
          final points = data['points'] ?? 0;
          final level = data['level'] ?? 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  user.email ?? '',
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      title: 'المستوى',
                      value: '$level',
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      title: 'النقاط',
                      value: '$points',
                      icon: Icons.star_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MenuTile(
                icon: Icons.edit_outlined,
                title: 'تعديل الحساب',
                subtitle: 'تعديل الاسم',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfilePage(),
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.emoji_events_outlined,
                title: 'الإنجازات',
                subtitle: 'إنجازاتك داخل مزاج',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementsPage(),
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.leaderboard_outlined,
                title: 'المتصدرين',
                subtitle: 'ترتيب اللاعبين',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE
// ============================================================

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final controller = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    controller.text =
        '${snapshot.data()?['nickname'] ?? user.displayName ?? ''}';

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final name = controller.text.trim();

    if (name.isEmpty) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'nickname': name,
    });

    await user.updateDisplayName(name);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الحساب'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: save,
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            subtitle: 'إعدادات الإشعارات',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.security_outlined,
            title: 'الخصوصية',
            subtitle: 'الخصوصية والأمان',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.info_outline,
            title: 'عن مزاج',
            subtitle: 'الإصدار والمعلومات',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'مزاج',
                applicationVersion: '1.0.0',
              );
            },
          ),
          _MenuTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'لوحة الإدارة',
            subtitle: 'إدارة التطبيق',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN
// ============================================================

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            icon: Icons.people_outline,
            title: 'المستخدمون',
            subtitle: 'إدارة المستخدمين',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.meeting_room_outlined,
            title: 'الرومات',
            subtitle: 'إدارة الرومات',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.campaign_outlined,
            title: 'الإعلانات',
            subtitle: 'إدارة الإعلانات',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.badge_outlined,
            title: 'التاقات',
            subtitle: 'موظفين وإداريين',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACHIEVEMENTS
// ============================================================

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'الإنجازات',
      icon: Icons.emoji_events_outlined,
      text: 'هنا راح تظهر إنجازات اللاعب.',
    );
  }
}

// ============================================================
// LEADERBOARD
// ============================================================

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتصدرين'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'ماكو لاعبين',
              subtitle: 'بعد ماكو ترتيب',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final name = '${data['nickname'] ?? 'لاعب'}';
              final points = data['points'] ?? 0;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    '$points نقطة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
// SIMPLE PAGE
// ============================================================

class _SimplePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _SimplePage({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 75,
              ),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.white38,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 5,
        ),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(.13),
          ),
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_left,
        ),
      ),
    );
  }
}
