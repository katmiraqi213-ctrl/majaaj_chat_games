import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ============================================================
// PROFILE SYSTEM
// ============================================================

const List<IconData> profileAvatars = [
  Icons.person,
  Icons.face,
  Icons.emoji_emotions,
  Icons.sports_esports,
  Icons.star,
  Icons.local_fire_department,
  Icons.diamond,
  Icons.workspace_premium,
];

int calculateLevel(int points) {
  if (points < 0) return 1;
  return (points ~/ 500) + 1;
}

double calculateProgress(int points) {
  final level = calculateLevel(points);
  final startPoints = (level - 1) * 500;
  final nextLevelPoints = level * 500;

  final progress =
      (points - startPoints) /
      (nextLevelPoints - startPoints);

  return progress.clamp(0.0, 1.0);
}

String getRankName(int points) {
  if (points >= 10000) {
    return '👑 أسطورة';
  }

  if (points >= 5000) {
    return '💎 ملكي';
  }

  if (points >= 2500) {
    return '🔥 محترف';
  }

  if (points >= 1000) {
    return '⭐ نجم';
  }

  if (points >= 500) {
    return '🏆 متقدم';
  }

  return '🎮 مبتدئ';
}

// ============================================================
// CHANGE POINTS
// ============================================================

Future<void> changeUserPoints(int amount) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  await FirebaseFirestore.instance.runTransaction(
    (transaction) async {
      final snapshot = await transaction.get(ref);

      final data = snapshot.data() ?? {};

      final oldPoints =
          (data['points'] ?? 0) as num;

      final newPoints =
          (oldPoints.toInt() + amount).clamp(0, 999999999);

      final newLevel =
          calculateLevel(newPoints);

      transaction.set(
        ref,
        {
          'points': newPoints,
          'level': newLevel,
        },
        SetOptions(merge: true),
      );
    },
  );
}

// ============================================================
// UPDATE PROFILE
// ============================================================

Future<void> updateUserProfile({
  required String nickname,
  required int avatarIndex,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set(
    {
      'nickname': nickname,
      'avatarIndex': avatarIndex,
    },
    SetOptions(merge: true),
  );
}

// ============================================================
// AVATAR WIDGET
// ============================================================

class ProfileAvatar extends StatelessWidget {
  final int avatarIndex;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.avatarIndex,
    this.radius = 42,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex =
        avatarIndex.clamp(
      0,
      profileAvatars.length - 1,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.pink,
            Colors.orange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 2,
            color: Colors.deepPurple.withOpacity(0.35),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.black87,
        child: Icon(
          profileAvatars[safeIndex],
          size: radius,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

  Future<void> editProfile(
    Map<String, dynamic> data,
  ) async {
    final nicknameController =
        TextEditingController(
      text: data['nickname'] ?? 'لاعب',
    );

    int selectedAvatar =
        (data['avatarIndex'] ?? 0) as int;

    final result =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF17121F),
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '✏️ تعديل الملف الشخصي',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    ProfileAvatar(
                      avatarIndex:
                          selectedAvatar,
                      radius: 48,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller:
                          nicknameController,
                      maxLength: 20,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'الاسم المستعار',
                        prefixIcon:
                            Icon(Icons.person),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Align(
                      alignment:
                          Alignment.centerRight,
                      child: Text(
                        'اختر صورتك',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          profileAvatars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder:
                          (context, index) {
                        final selected =
                            selectedAvatar ==
                                index;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedAvatar =
                                  index;
                            });
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 200,
                            ),
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color: selected
                                  ? Colors
                                      .deepPurple
                                  : Colors
                                      .grey
                                      .shade900,
                              border: Border.all(
                                color: selected
                                    ? Colors
                                        .purpleAccent
                                    : Colors
                                        .transparent,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              profileAvatars[
                                  index],
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed: () async {
                          final nickname =
                              nicknameController
                                  .text
                                  .trim();

                          if (nickname.isEmpty) {
                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'اكتب اسم مستعار',
                                ),
                              ),
                            );
                            return;
                          }

                          await updateUserProfile(
                            nickname: nickname,
                            avatarIndex:
                                selectedAvatar,
                          );

                          if (context.mounted) {
                            Navigator.pop(
                              context,
                              true,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.save,
                        ),
                        label: const Text(
                          'حفظ التغييرات',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nicknameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'لا يوجد حساب',
          ),
        ),
      );
    }

    final userRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '👤 حسابي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تعديل الحساب',
            onPressed: () async {
              final snapshot =
                  await userRef.get();

              final data =
                  snapshot.data() ?? {};

              if (!context.mounted) return;

              await editProfile(data);
            },
            icon: const Icon(
              Icons.edit,
            ),
          ),
        ],
      ),

      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream: userRef.snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data?.data() ?? {};

          final nickname =
              data['nickname'] ??
                  'لاعب';

          final points =
              (data['points'] ?? 0)
                  as num;

          final wins =
              (data['wins'] ?? 0)
                  as num;

          final losses =
              (data['losses'] ?? 0)
                  as num;

          final avatarIndex =
              (data['avatarIndex'] ?? 0)
                  as int;

          final level =
              calculateLevel(
            points.toInt(),
          );

          final progress =
              calculateProgress(
            points.toInt(),
          );

          final rank =
              getRankName(
            points.toInt(),
          );

          final currentLevelPoints =
              (level - 1) * 500;

          final nextLevelPoints =
              level * 500;

          final remaining =
              nextLevelPoints -
                  points.toInt();

          return RefreshIndicator(
            onRefresh: () async {
              await userRef.get();
            },

            child: ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [

                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(22),

                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(28),

                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Color(0xFF512DA8),
                        Color(0xFF7B1FA2),
                        Color(0xFFE91E63),
                      ],
                    ),

                    boxShadow: [
                      BoxShadow(
                        blurRadius: 25,
                        color: Colors
                            .deepPurple
                            .withOpacity(
                                0.30),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      ProfileAvatar(
                        avatarIndex:
                            avatarIndex,
                        radius: 48,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        nickname,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 27,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withOpacity(
                                  0.20),
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      20),
                        ),
                        child: Text(
                          rank,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Icon(
                            Icons.star,
                            color:
                                Colors.amber,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            '${points.toInt()} نقطة',
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // LEVEL
                // ==================================================

                Card(
                  elevation: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                            18),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Row(
                          children: [

                            Container(
                              padding:
                                  const EdgeInsets
                                      .all(10),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .deepPurple
                                    .withOpacity(
                                        0.15),
                                shape:
                                    BoxShape
                                        .circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .workspace_premium,
                                color:
                                    Colors
                                        .purpleAccent,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [

                                  Text(
                                    'المستوى $level',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          19,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    '$points / $nextLevelPoints نقطة',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              '${(progress * 100).round()}%',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(20),
                          child:
                              LinearProgressIndicator(
                            minHeight: 10,
                            value: progress,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          remaining > 0
                              ? 'باقي $remaining نقطة للمستوى القادم 🚀'
                              : 'وصلت للمستوى القادم 🎉',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'بدأ المستوى من $currentLevelPoints نقطة',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // STATS
                // ==================================================

                Row(
                  children: [

                    Expanded(
                      child: _statCard(
                        icon:
                            Icons.emoji_events,
                        title:
                            'الانتصارات',
                        value:
                            wins.toInt()
                                .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _statCard(
                        icon:
                            Icons.close,
                        title:
                            'الخسائر',
                        value:
                            losses.toInt()
                                .toString(),
                      ),
                    ),

                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                _statCard(
                  icon:
                      Icons.emoji_events_outlined,
                  title:
                      'الرتبة الحالية',
                  value:
                      rank,
                  fullWidth: true,
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // ACCOUNT
                // ==================================================

                const Text(
                  'إعدادات الحساب',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child:
                          Icon(Icons.edit),
                    ),
                    title:
                        const Text(
                      'تعديل الملف الشخصي',
                    ),
                    subtitle:
                        const Text(
                      'الاسم والصورة الرمزية',
                    ),
                    trailing:
                        const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 18,
                    ),
                    onTap: () async {
                      await editProfile(
                        data,
                      );
                    },
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child:
                          Icon(Icons.logout),
                    ),
                    title:
                        const Text(
                      'تسجيل الخروج',
                    ),
                    subtitle:
                        const Text(
                      'الخروج من حساب مزاج',
                    ),
                    trailing:
                        const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 18,
                    ),
                    onTap: () async {
                      final confirm =
                          await showDialog<bool>(
                        context: context,
                        builder:
                            (context) {
                          return AlertDialog(
                            title:
                                const Text(
                              'تسجيل الخروج',
                            ),
                            content:
                                const Text(
                              'متأكد تريد تسجيل الخروج؟',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(
                                  context,
                                  false,
                                ),
                                child:
                                    const Text(
                                  'إلغاء',
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(
                                  context,
                                  true,
                                ),
                                child:
                                    const Text(
                                  'خروج',
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseAuth
                            .instance
                            .signOut();
                      }
                    },
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                Center(
                  child: Text(
                    'مزاج • دردشة وألعاب أونلاين 🎮',
                    style:
                        TextStyle(
                      color: Colors.grey
                          .shade600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [

            Container(
              padding:
                  const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(
                color: Colors.deepPurple
                    .withOpacity(0.15),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    Colors.purpleAccent,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// MAZAAJ APP SHELL - UI FIRST
// Ludo is intentionally kept separate until the core app UI is finished.
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151522),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

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
        return snapshot.data == null ? const LoginPage() : const HomePage();
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
            _MazaajLogo(size: 88),
            SizedBox(height: 18),
            Text('مزاج', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _MazaajLogo extends StatelessWidget {
  final double size;
  const _MazaajLogo({this.size = 58});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B5CFF), Color(0xFFEC4899), Color(0xFFFF9F43)],
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF9B5CFF).withOpacity( .30), blurRadius: 22)],
      ),
      child: Center(
        child: Icon(Icons.auto_awesome_rounded, size: size * .48, color: Colors.white),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _toast('اكتب الإيميل وكلمة المرور'); return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'تعذر تسجيل الدخول');
    } catch (e) { _toast('حدث خطأ: $e'); }
    if (mounted) setState(() => loading = false);
  }

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const _MazaajLogo(size: 96),
                  const SizedBox(height: 18),
                  const Text('مزاج', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('دردشة • ألعاب • أصدقاء', style: TextStyle(color: Colors.white60, fontSize: 16)),
                  const SizedBox(height: 36),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'الإيميل', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: obscure,
                    decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, height: 54,
                    child: FilledButton(onPressed: loading ? null : login,
                      child: loading ? const CircularProgressIndicator() : const Text('تسجيل الدخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 8),
                  TextButton(onPressed: loading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: const Text('إنشاء حساب جديد')),
                  const SizedBox(height: 22),
                  const Text('تسجيل الدخول الاجتماعي ورقم الهاتف نضيفهما بعد تثبيت إعدادات Firebase الخاصة بالمشروع.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  Future<void> register() async {
    final n = name.text.trim();
    final e = email.text.trim();
    if (n.length < 2 || e.isEmpty || password.text.length < 6) {
      _toast('الاسم مطلوب وكلمة المرور 6 أحرف على الأقل'); return;
    }
    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: e, password: password.text);
      await cred.user?.updateDisplayName(n);
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid, 'nickname': n, 'email': e, 'points': 0, 'level': 1,
        'avatarIndex': 0, 'walletBalance': 0, 'role': 'user', 'tag': '',
        'wins': 0, 'losses': 0, 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) { _toast(e.message ?? 'فشل إنشاء الحساب'); }
    catch (e) { _toast('حدث خطأ: $e'); }
    if (mounted) setState(() => loading = false);
  }
  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const _MazaajLogo(size: 72), const SizedBox(height: 24),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم المستعار', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'الإيميل', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: loading ? null : register,
          child: loading ? const CircularProgressIndicator() : const Text('إنشاء الحساب'))),
      ])),),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0;
  final pages = const [RoomsPage(), GamesPage(), WalletPage(), ProfilePage()];
  final labels = const ['الرومات', 'الألعاب', 'المحفظة', 'حسابي'];
  final icons = const [Icons.forum_outlined, Icons.sports_esports_outlined, Icons.account_balance_wallet_outlined, Icons.person_outline];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: List.generate(labels.length, (i) => NavigationDestination(icon: Icon(icons[i]), selectedIcon: Icon(_selectedIcon(i)), label: labels[i])),
      ),
    );
  }
  IconData _selectedIcon(int i) => [Icons.forum, Icons.sports_esports, Icons.account_balance_wallet, Icons.person][i];
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مزاج', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())), icon: const Icon(Icons.notifications_none_rounded)),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())), icon: const Icon(Icons.search_rounded)),
      ]),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: FirebaseFirestore.instance.collection('rooms').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل الرومات'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), children: [
            const _SectionTitle(title: 'أهلاً بك في مزاج', subtitle: 'اختار روم وادخل للجو'),
            const SizedBox(height: 8),
            const _QuickActions(),
            const SizedBox(height: 14),
            Row(children: [const Expanded(child: Text('الرومات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))), Text('${docs.length} روم', style: const TextStyle(color: Colors.white54))]),
            const SizedBox(height: 8),
            if (docs.isEmpty) const _EmptyState(icon: Icons.forum_outlined, title: 'ماكو رومات حالياً', subtitle: 'راح تظهر الرومات هنا أول ما تنضاف.')
            else ...docs.map((doc) => _RoomCard(data: doc.data(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomPage(data: doc.data()))))),
          ]);
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _ActionTile(icon: Icons.add_circle_outline, title: 'إنشاء روم', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomPage())))),
    const SizedBox(width: 10),
    Expanded(child: _ActionTile(icon: Icons.group_outlined, title: 'الأصدقاء', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage())))),
  ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.onTap});
  @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [Icon(icon, size: 25), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))), const Icon(Icons.chevron_right)]))));
}

class _RoomCard extends StatelessWidget {
  final Map<String,dynamic> data; final VoidCallback onTap;
  const _RoomCard({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final name = '${data['name'] ?? 'روم مزاج'}';
    final count = data['membersCount'] ?? 0;
    final cover = '${data['coverUrl'] ?? ''}';
    return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Column(children: [
      SizedBox(height: 110, width: double.infinity, child: cover.isNotEmpty ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_,__,___) => const _RoomCover()) : const _RoomCover()),
      Padding(padding: const EdgeInsets.fromLTRB(14,12,14,14), child: Row(children: [
        const CircleAvatar(child: Icon(Icons.forum_rounded)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text('$count عضو • دردشة وصوت', style: const TextStyle(color: Colors.white54))])), const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ])),
    ])));
  }
}

class _RoomCover extends StatelessWidget { const _RoomCover(); @override Widget build(BuildContext context) => Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5B21B6),Color(0xFFDB2777)])), child: const Center(child: Icon(Icons.auto_awesome, size: 40, color: Colors.white70))); }

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الألعاب', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameHistoryPage()),
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(
            title: 'ألعاب مزاج',
            subtitle: 'اللعب أونلاين • نقاط • ترتيب',
          ),
          const SizedBox(height: 12),
          _GameCard(
            icon: Icons.grid_4x4_rounded,
            title: 'لودو',
            subtitle: '2 أو 4 لاعبين',
            badge: 'جاهزة',
            enabled: false,
            onTap: () {},
          ),
          _GameCard(
            icon: Icons.style_rounded,
            title: 'أونو',
            subtitle: 'بطاقات وتحديات',
            badge: 'قريباً',
            onTap: () {},
          ),
          _GameCard(
            icon: Icons.radio_button_checked_rounded,
            title: 'كيرم',
            subtitle: 'تنافس أونلاين',
            badge: 'قريباً',
            onTap: () {},
          ),
          _GameCard(
            icon: Icons.close_rounded,
            title: 'XO',
            subtitle: '1 ضد 1',
            badge: 'قريباً',
            onTap: () {},
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
  final VoidCallback onTap;
  final bool enabled;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: primary.withOpacity(.14),
                ),
                child: Icon(icon, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: enabled
                      ? Colors.green.withOpacity(.15)
                      : Colors.white.withOpacity(.06),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.greenAccent : Colors.white54,
                    fontWeight: FontWeight.bold,
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

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('لا يوجد حساب')),
      );
    }

    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletHistoryPage()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userStream,
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};
          final balance = (data['walletBalance'] as num?)?.toDouble() ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFFBE185D)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رصيد المحفظة', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(0)} نقطة',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TopUpPage()),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('شحن'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WalletHistoryPage()),
                            ),
                            icon: const Icon(Icons.history),
                            label: const Text('الحركات'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'طرق الشحن',
                subtitle: 'نفعّل الطرق المتاحة بعد ربط بوابة الدفع',
              ),
              const SizedBox(height: 8),
              const _InfoTile(
                icon: Icons.credit_card,
                title: 'بطاقات الدفع',
                subtitle: 'ماستر كارد / فيزا / البطاقات المدعومة',
              ),
              const _InfoTile(
                icon: Icons.phone_android,
                title: 'رصيد الهاتف',
                subtitle: 'شحن عن طريق رصيد الشبكة حسب توفر الخدمة',
              ),
              const _InfoTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'شحن يدوي',
                subtitle: 'طلب إلى الإدارة ومراجعة العملية',
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfilePageDetails extends StatelessWidget { final Map<String,dynamic> data; const ProfilePageDetails({super.key,required this.data}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الملف الشخصي')),body:Center(child:Text('تفاصيل ${data['nickname']??'اللاعب'}'))); }

class _StatBox extends StatelessWidget { final String label,value; final IconData icon; const _StatBox({required this.label,required this.value,required this.icon}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Column(children:[Icon(icon,size:24),const SizedBox(height:5),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text(label,style:const TextStyle(color:Colors.white54,fontSize:12))]))); }
class _MenuTile extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback onTap; const _MenuTile({required this.icon,required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext context)=>Card(child:ListTile(onTap:onTap,leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right))); }
class _InfoTile extends StatelessWidget { final IconData icon; final String title,subtitle; const _InfoTile({required this.icon,required this.title,required this.subtitle}); @override Widget build(BuildContext context)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(title),subtitle:Text(subtitle))); }
class _SectionTitle extends StatelessWidget { final String title,subtitle; const _SectionTitle({required this.title,required this.subtitle}); @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white54))]); }
class _EmptyState extends StatelessWidget { final IconData icon; final String title,subtitle; const _EmptyState({required this.icon,required this.title,required this.subtitle}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:70),child:Column(children:[Icon(icon,size:60,color:Colors.white24),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Colors.white38),textAlign:TextAlign.center)])); }

class RoomPage extends StatelessWidget { final Map<String,dynamic> data; const RoomPage({super.key,required this.data}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('${data['name']??'الروم'}')),body:Column(children:[Expanded(child:ListView(padding:const EdgeInsets.all(16),children:[const _EmptyState(icon:Icons.forum_outlined,title:'الدردشة',subtitle:'هنا راح تظهر رسائل الروم والصوت والفعاليات.')])),SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(decoration:const InputDecoration(hintText:'اكتب رسالة...'))),const SizedBox(width:8),IconButton.filled(onPressed:(){},icon:const Icon(Icons.send))])))])); }
class CreateRoomPage extends StatelessWidget { const CreateRoomPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إنشاء روم')),body:const Center(child:Text('واجهة إنشاء الروم جاهزة للربط مع صلاحيات الإدارة.'))); }
class FriendsPage extends StatelessWidget { const FriendsPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'الأصدقاء',icon:Icons.group_outlined,text:'قائمة الأصدقاء والطلبات راح تنربط هنا.'); }
class SearchPage extends StatelessWidget { const SearchPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('بحث')),body:Padding(padding:const EdgeInsets.all(16),child:TextField(autofocus:true,decoration:const InputDecoration(hintText:'ابحث عن لاعب أو روم...',prefixIcon:Icon(Icons.search))))); }
class NotificationsPage extends StatelessWidget { const NotificationsPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'الإشعارات',icon:Icons.notifications_none,text:'الإشعارات والتنبيهات راح تظهر هنا.'); }
class GameHistoryPage extends StatelessWidget { const GameHistoryPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'سجل الألعاب',icon:Icons.history,text:'نتائج الألعاب والإحصائيات راح تظهر هنا.'); }
class WalletHistoryPage extends StatelessWidget { const WalletHistoryPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'حركات المحفظة',icon:Icons.receipt_long_outlined,text:'عمليات الشحن والسحب والمراجعات راح تظهر هنا.'); }
class TopUpPage extends StatelessWidget { const TopUpPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'شحن المحفظة',icon:Icons.add_card,text:'واجهة الشحن جاهزة للتوصيل ببوابة الدفع.'); }
class AchievementsPage extends StatelessWidget { const AchievementsPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'الإنجازات',icon:Icons.workspace_premium_outlined,text:'الشارات والجوائز راح تظهر هنا.'); }
class LeaderboardPage extends StatelessWidget { const LeaderboardPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'المتصدرون',icon:Icons.leaderboard_outlined,text:'ترتيب اللاعبين حسب النقاط والفوز.'); }
class SettingsPage extends StatelessWidget { const SettingsPage({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(padding:const EdgeInsets.all(12),children:[_MenuTile(icon:Icons.notifications_outlined,title:'الإشعارات',subtitle:'إعدادات التنبيهات',onTap: _noop),_MenuTile(icon:Icons.lock_outline,title:'الخصوصية والأمان',subtitle:'إدارة الحساب والأمان',onTap:_noop),_MenuTile(icon:Icons.language_outlined,title:'اللغة',subtitle:'العربية',onTap:_noop),_MenuTile(icon:Icons.info_outline,title:'عن مزاج',subtitle:'الإصدار 1.0.0',onTap:_noop)])); static void _noop(){} }
class AdminPage extends StatelessWidget { const AdminPage({super.key}); @override Widget build(BuildContext context)=>const _SimplePage(title:'لوحة الإدارة',icon:Icons.admin_panel_settings_outlined,text:'هنا نضيف إدارة المستخدمين، الرومات، التاقات، الصلاحيات، الإعلانات والشحن.'); }
class _SimplePage extends StatelessWidget { final String title,text; final IconData icon; const _SimplePage({required this.title,required this.icon,required this.text}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(title)),body:Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:70,color:Theme.of(context).colorScheme.primary),const SizedBox(height:18),Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:16,color:Colors.white60))])))); }
