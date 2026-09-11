                const SizedBox(
                  height: 18,
                ),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(10),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .deepPurple
                                    .withOpacity(0.15),
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .workspace_premium,
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
                                    'المستوى $level',
                                    style:
                                        const TextStyle(
                                      fontSize: 19,
                                      fontWeight:
                                          FontWeight.bold,
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
                                          Colors.grey,
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
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
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
                  height: 18,
                ),

                _SectionTitle(
                  title: 'الحساب',
                ),

                const SizedBox(
                  height: 8,
                ),

                _MenuTile(
                  icon:
                      Icons.people_outline,
                  title:
                      'الأصدقاء',
                  subtitle:
                      'إدارة قائمة الأصدقاء',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FriendsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.notifications_outlined,
                  title:
                      'الإشعارات',
                  subtitle:
                      'شاهد آخر التنبيهات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const NotificationsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.history,
                  title:
                      'سجل الألعاب',
                  subtitle:
                      'نتائج ومبارياتك السابقة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const GameHistoryPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.emoji_events_outlined,
                  title:
                      'الإنجازات',
                  subtitle:
                      'إنجازاتك ومستواك',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AchievementsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.settings_outlined,
                  title:
                      'الإعدادات',
                  subtitle:
                      'إعدادات التطبيق والحساب',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth
                        .instance
                        .signOut();
                  },
                  icon: const Icon(
                    Icons.logout,
                  ),
                  label: const Text(
                    'تسجيل الخروج',
                  ),
                ),

                const SizedBox(
                  height: 30,
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
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color:
                  Colors.amber,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BASE64 IMAGE
// ============================================================

Widget _buildBase64Image(
  Map<String, dynamic> message,
) {
  final encoded =
      message['imageBase64'];

  if (encoded is! String ||
      encoded.isEmpty) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
        ),
      ),
    );
  }

  try {
    return Image.memory(
      base64Decode(encoded),
      width: 280,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) =>
              const SizedBox(
        height: 120,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
          ),
        ),
      ),
    );
  } catch (_) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
        ),
      ),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
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
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب الإيميل وكلمة المرور',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'حدث خطأ في تسجيل الدخول';

      if (e.code ==
          'user-not-found') {
        message =
            'الحساب غير موجود';
      } else if (e.code ==
          'wrong-password') {
        message =
            'كلمة المرور غير صحيحة';
      } else if (e.code ==
          'invalid-credential') {
        message =
            'الإيميل أو كلمة المرور غير صحيحة';
      } else if (e.code ==
          'invalid-email') {
        message =
            'الإيميل غير صحيح';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    gradient:
                        const LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        Colors.pink,
                        Colors.orange,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 25,
                        color: Colors
                            .deepPurple
                            .withOpacity(
                                0.35),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .sports_esports,
                    size: 48,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'مزاج',
                  style:
                      TextStyle(
                    fontSize: 34,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'دردشة • ألعاب • أصدقاء',
                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                TextField(
                  controller:
                      emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'البريد الإلكتروني',
                    prefixIcon:
                        Icon(Icons.email_outlined),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      passwordController,
                  obscureText:
                      obscure,
                  decoration:
                      InputDecoration(
                    labelText:
                        'كلمة المرور',
                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          obscure =
                              !obscure;
                        });
                      },
                      icon: Icon(
                        obscure
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : login,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'دخول',
                            style:
                                TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    );
                  },
                  child:
                      const Text(
                    'إنشاء حساب جديد',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'firebase_options.dart';

// ============================================================
// VOICE ROOM CONFIG
// ============================================================
// ضع بيانات Agora الخاصة بمشروع مزاج هنا.
// إذا كان المشروع يستخدم App Certificate فاستعمل Token صالح للقناة.
// ============================================================
const String kAgoraAppId = 'PUT_YOUR_AGORA_APP_ID_HERE';
const String kAgoraTempToken = 'PUT_YOUR_AGORA_TOKEN_HERE';

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
                ),                const SizedBox(
                  height: 18,
                ),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(10),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .deepPurple
                                    .withOpacity(0.15),
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .workspace_premium,
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
                                    'المستوى $level',
                                    style:
                                        const TextStyle(
                                      fontSize: 19,
                                      fontWeight:
                                          FontWeight.bold,
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
                                          Colors.grey,
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
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
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
                  height: 18,
                ),

                _SectionTitle(
                  title: 'الحساب',
                ),

                const SizedBox(
                  height: 8,
                ),

                _MenuTile(
                  icon:
                      Icons.people_outline,
                  title:
                      'الأصدقاء',
                  subtitle:
                      'إدارة قائمة الأصدقاء',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FriendsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.notifications_outlined,
                  title:
                      'الإشعارات',
                  subtitle:
                      'شاهد آخر التنبيهات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const NotificationsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.history,
                  title:
                      'سجل الألعاب',
                  subtitle:
                      'نتائج ومبارياتك السابقة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const GameHistoryPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.emoji_events_outlined,
                  title:
                      'الإنجازات',
                  subtitle:
                      'إنجازاتك ومستواك',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AchievementsPage(),
                      ),
                    );
                  },
                ),

                _MenuTile(
                  icon:
                      Icons.settings_outlined,
                  title:
                      'الإعدادات',
                  subtitle:
                      'إعدادات التطبيق والحساب',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth
                        .instance
                        .signOut();
                  },
                  icon: const Icon(
                    Icons.logout,
                  ),
                  label: const Text(
                    'تسجيل الخروج',
                  ),
                ),

                const SizedBox(
                  height: 30,
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
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color:
                  Colors.amber,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BASE64 IMAGE
// ============================================================

Widget _buildBase64Image(
  Map<String, dynamic> message,
) {
  final encoded =
      message['imageBase64'];

  if (encoded is! String ||
      encoded.isEmpty) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
        ),
      ),
    );
  }

  try {
    return Image.memory(
      base64Decode(encoded),
      width: 280,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) =>
              const SizedBox(
        height: 120,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
          ),
        ),
      ),
    );
  } catch (_) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
        ),
      ),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
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
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب الإيميل وكلمة المرور',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'حدث خطأ في تسجيل الدخول';

      if (e.code ==
          'user-not-found') {
        message =
            'الحساب غير موجود';
      } else if (e.code ==
          'wrong-password') {
        message =
            'كلمة المرور غير صحيحة';
      } else if (e.code ==
          'invalid-credential') {
        message =
            'الإيميل أو كلمة المرور غير صحيحة';
      } else if (e.code ==
          'invalid-email') {
        message =
            'الإيميل غير صحيح';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    gradient:
                        const LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        Colors.pink,
                        Colors.orange,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 25,
                        color: Colors
                            .deepPurple
                            .withOpacity(
                                0.35),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .sports_esports,
                    size: 48,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'مزاج',
                  style:
                      TextStyle(
                    fontSize: 34,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'دردشة • ألعاب • أصدقاء',
                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                TextField(
                  controller:
                      emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'البريد الإلكتروني',
                    prefixIcon:
                        Icon(Icons.email_outlined),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      passwordController,
                  obscureText:
                      obscure,
                  decoration:
                      InputDecoration(
                    labelText:
                        'كلمة المرور',
                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          obscure =
                              !obscure;
                        });
                      },
                      icon: Icon(
                        obscure
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : login,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'دخول',
                            style:
                                TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    );
                  },
                  child:
                      const Text(
                    'إنشاء حساب جديد',
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
