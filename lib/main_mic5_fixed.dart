import 'dart:async';
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
// ضع بيانات Agora الخاصة بمشروع مزاج هنا.
// إذا كان المشروع يستخدم App Certificate فاستعمل Token صالح للقناة.
// ============================================================
const String kAgoraAppId = '17efeb1c418a44e1b187a90eaa591023';
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
// ADMIN / IMAGE HELPERS
// ============================================================
bool isAdminRole(String role) => role == 'admin' || role == 'superadmin' || role == 'owner' || role == 'مدير' || role == 'أدمن';

Future<Map<String, dynamic>> currentUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};
  final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return snap.data() ?? {};
}

Future<String?> pickBase64Image(ImagePicker picker, {int maxBytes = 450 * 1024}) async {
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1400);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > maxBytes) return null;
  return base64Encode(bytes);
}

Widget base64Avatar(String encoded, {double radius = 24}) {
  try {
    return CircleAvatar(radius: radius, backgroundImage: MemoryImage(base64Decode(encoded)));
  } catch (_) {
    return CircleAvatar(radius: radius, child: const Icon(Icons.person));
  }
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
  String imageBase64 = '',
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
      'imageBase64': imageBase64,
    },
    SetOptions(merge: true),
  );
}

// ============================================================
// AVATAR WIDGET
// ============================================================

Widget _buildBase64Image(Map<String, dynamic> message) {
  final encoded = message['imageBase64'];
  if (encoded is! String || encoded.isEmpty) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
  try {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.memory(
        base64Decode(encoded),
        width: 280,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 120,
          width: 280,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  } catch (_) {
    return const SizedBox(
      height: 120,
      width: 280,
      child: Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final int avatarIndex;
  final double radius;
  final String? imageBase64;
  const ProfileAvatar({super.key, required this.avatarIndex, this.radius = 42, this.imageBase64});
  @override
  Widget build(BuildContext context) {
    final safeIndex = avatarIndex.clamp(0, profileAvatars.length - 1);
    ImageProvider? image;
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try { image = MemoryImage(base64Decode(imageBase64!)); } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.pink, Colors.orange]),
        boxShadow: [BoxShadow(blurRadius: 18, spreadRadius: 2, color: Colors.deepPurple.withOpacity(.35))],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.black87,
        backgroundImage: image,
        child: image == null ? Icon(profileAvatars[safeIndex], size: radius, color: Colors.white) : null,
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

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _pickerForProfile = ImagePicker();

  Future<void> editProfile(
    Map<String, dynamic> data,
  ) async {
    final nicknameController =
        TextEditingController(
      text: data['nickname'] ?? 'لاعب',
    );

    int selectedAvatar = (data['avatarIndex'] ?? 0) as int;
    String selectedImage = '${data['imageBase64'] ?? ''}';

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

                    GestureDetector(
                      onTap: () async {
                        final picked = await pickBase64Image(_pickerForProfile);
                        if (picked != null) setModalState(() => selectedImage = picked);
                      },
                      child: ProfileAvatar(
                        avatarIndex: selectedAvatar,
                        radius: 48,
                        imageBase64: selectedImage,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('اضغط على الصورة لتغييرها', style: TextStyle(color: Colors.white54)),

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
                            avatarIndex: selectedAvatar,
                            imageBase64: selectedImage,
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
          IconButton(tooltip: 'لوحة الإدارة', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())), icon: const Icon(Icons.admin_panel_settings_outlined)),
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

          final avatarIndex = (data['avatarIndex'] ?? 0) as int;
          final imageBase64 = '${data['imageBase64'] ?? ''}';

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
                        avatarIndex: avatarIndex,
                        radius: 48,
                        imageBase64: imageBase64,
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
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashPage();
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profile) {
            if (!profile.hasData) return const SplashPage();
            final data = profile.data!.data() ?? {};
            if (data['banned'] == true) {
              return Scaffold(
                body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.block, size: 70, color: Colors.redAccent),
                  const SizedBox(height: 18),
                  const Text('تم حظر هذا الحساب', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('تواصل مع إدارة مزاج إذا كان الحظر بالخطأ.', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('تسجيل الخروج')),
                ]))),
              );
            }
            return const HomePage();
          },
        );
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
            else ...docs.map((doc) => _RoomCard(roomId: doc.id, data: doc.data())),
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
  final String roomId;
  final Map<String, dynamic> data;

  const _RoomCard({
    required this.roomId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${data['name'] ?? 'روم مزاج'}';
    final count = data['membersCount'] ?? 0;
    final cover = '${data['coverUrl'] ?? ''}';
    final coverBase64 = '${data['coverBase64'] ?? ''}';
    final status = '${data['status'] ?? ''}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomPage(roomId: roomId, data: data),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: coverBase64.isNotEmpty
                  ? Image.memory(base64Decode(coverBase64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _RoomCover())
                  : cover.isNotEmpty
                  ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _RoomCover(),
                    )
                  : const _RoomCover(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.forum_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          status.isNotEmpty ? status : '$count عضو • دردشة وصوت وصور',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCover extends StatelessWidget {
  const _RoomCover();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5B21B6), Color(0xFFDB2777)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, size: 40, color: Colors.white70),
        ),
      );
}

class _AgoraVoiceController {
  RtcEngine? engine;
  bool initialized = false;
  bool joined = false;

  Future<bool> init({required String channelName}) async {
    if (initialized) return joined;
    if (kAgoraAppId.startsWith('PUT_') ||
        kAgoraTempToken.startsWith('PUT_') ||
        kAgoraAppId.trim().isEmpty ||
        kAgoraTempToken.trim().isEmpty) {
      return false;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return false;

    final e = createAgoraRtcEngine();
    await e.initialize(
      const RtcEngineContext(
        appId: kAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await e.enableAudio();
    await e.setEnableSpeakerphone(true);

    await e.joinChannel(
      token: kAgoraTempToken,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );

    engine = e;
    initialized = true;
    joined = true;
    return true;
  }

  Future<void> setMic(bool enabled) async {
    final e = engine;
    if (e == null) return;
    await e.muteLocalAudioStream(!enabled);
  }

  Future<void> setMute(bool muted) async {
    final e = engine;
    if (e == null) return;
    await e.muteLocalAudioStream(muted);
  }

  Future<void> dispose() async {
    final e = engine;
    engine = null;
    initialized = false;
    joined = false;
    if (e != null) {
      try {
        await e.leaveChannel();
      } catch (_) {}
      try {
        await e.release();
      } catch (_) {}
    }
  }
}

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final _AgoraVoiceController _voice = _AgoraVoiceController();

  bool _onMic = false;
  bool _micMuted = false;
  bool _voiceLoading = true;
  bool _imageUploading = false;
  bool _canManageRoom = false;
  String _myRole = 'user';

  CollectionReference<Map<String, dynamic>> get _membersRef =>
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('members');

  final List<Map<String, dynamic>> _mics = [
    {
      'name': 'المالك',
      'role': 'المالك',
      'icon': Icons.workspace_premium,
      'color': Colors.amber,
    },
    {
      'name': 'أدمن',
      'role': 'أدمن',
      'icon': Icons.admin_panel_settings,
      'color': Colors.blue,
    },
    {
      'name': 'مشرف',
      'role': 'مشرف',
      'icon': Icons.shield,
      'color': Colors.green,
    },
    {
      'name': 'مايك 4',
      'role': 'عضو',
      'icon': Icons.person,
      'color': Colors.purple,
    },
    {
      'name': 'مايك 5',
      'role': 'عضو',
      'icon': Icons.person,
      'color': Colors.purple,
    },
  ];

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages');

  @override
  void initState() {
    super.initState();
    _loadRoomAccess();
    _startVoice();
  }

  Future<void> _loadRoomAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = profile.data() ?? {};
      final role = '${data['role'] ?? 'user'}';
      final ownerId = '${widget.data['ownerId'] ?? ''}';
      final allowed = isAdminRole(role) || ownerId == user.uid || '${widget.data['adminIds'] ?? ''}'.contains(user.uid);
      if (mounted) setState(() { _myRole = role; _canManageRoom = allowed; });
      await _membersRef.doc(user.uid).set({
        'uid': user.uid,
        'nickname': '${data['nickname'] ?? user.displayName ?? 'لاعب'}',
        'avatarIndex': (data['avatarIndex'] ?? 0),
        'imageBase64': '${data['imageBase64'] ?? ''}',
        'role': ownerId == user.uid ? 'المالك' : role,
        'online': true,
        'onMic': false,
        'muted': false,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _setMemberOnline(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try { await _membersRef.doc(uid).set({'online': online, 'onMic': online ? _onMic : false, 'muted': _micMuted}, SetOptions(merge: true)); } catch (_) {}
  }

  Future<void> _startVoice() async {
    setState(() => _voiceLoading = true);
    try {
      final ok = await _voice.init(channelName: 'mazaaj_${widget.roomId}');
      if (!mounted) return;
      setState(() => _voiceLoading = false);

      if (!ok) {
        _showVoiceConfigMessage();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _voiceLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تشغيل الصوت: $e')),
      );
    }
  }

  void _showVoiceConfigMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'الصوت جاهز، فقط أضف Agora App ID وToken داخل main.dart',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_setMemberOnline(false));
    unawaited(_voice.dispose());
    _messageController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'المالك':
        return Colors.amber;
      case 'أدمن':
        return Colors.blue;
      case 'مشرف':
        return Colors.green;
      default:
        return Colors.purpleAccent;
    }
  }

  Future<void> _toggleMic() async {
    if (!_voice.initialized) {
      _showVoiceConfigMessage();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      if (_onMic) {
        await _voice.setMic(false);
        await _membersRef.doc(uid).set({
          'onMic': false,
          'muted': false,
        }, SetOptions(merge: true));
        if (mounted) setState(() { _onMic = false; _micMuted = false; });
        return;
      }

      // Maximum 5 active microphones in the room.
      final active = await _membersRef.where('onMic', isEqualTo: true).get();
      if (active.docs.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المايكات الخمسة ممتلئة حالياً')),
          );
        }
        return;
      }

      await _voice.setMic(true);
      await _membersRef.doc(uid).set({
        'onMic': true,
        'muted': false,
        'micJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() { _onMic = true; _micMuted = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎙️ صعدت على المايك'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      try { await _voice.setMic(false); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التحكم بالمايك: $e')),
      );
    }
  }

  Future<void> _toggleMute() async {
    if (!_onMic) return;
    final next = !_micMuted;
    try {
      await _voice.setMute(next);
      if (!mounted) return;
      setState(() => _micMuted = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر كتم المايك: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = '${profile.data()?['nickname'] ?? user.displayName ?? 'لاعب'}';

      await _messagesRef.add({
        'type': 'text',
        'text': text,
        'userId': user.uid,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _scrollMessages();
    } catch (e) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الرسالة: $e')),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_imageUploading) return;

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (file == null) return;

      setState(() => _imageUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await file.readAsBytes();

      // Firestore document size is limited, and Base64 increases the size.
      // Keep images small enough to fit safely in a message document.
      if (bytes.length > 500 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الصورة كبيرة. اختار صورة أصغر من 500KB.'),
            ),
          );
        }
        return;
      }

      final imageBase64 = base64Encode(bytes);

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = '${profile.data()?['nickname'] ?? user.displayName ?? 'لاعب'}';

      await _messagesRef.add({
        'type': 'image',
        'imageBase64': imageBase64,
        'userId': user.uid,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _scrollMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة: $e')),
      );
    } finally {
      if (mounted) setState(() => _imageUploading = false);
    }
  }

  void _scrollMessages() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_messagesController.hasClients) {
        _messagesController.animateTo(
          _messagesController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _micCard(Map<String, dynamic>? member, int index) {
    final occupied = member != null;
    final name = occupied ? '${member['nickname'] ?? 'لاعب'}' : 'مايك ${index + 1}';
    final role = occupied ? '${member['role'] ?? 'عضو'}' : 'فارغ';
    final muted = occupied && member['muted'] == true;
    final isMe = occupied && member['uid'] == FirebaseAuth.instance.currentUser?.uid;
    final color = occupied ? _roleColor(role) : Colors.white24;

    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.12),
                  border: Border.all(
                    color: isMe ? Colors.greenAccent : color,
                    width: isMe ? 3 : 2,
                  ),
                ),
                child: occupied && '${member['imageBase64'] ?? ''}'.isNotEmpty
                    ? ClipOval(child: base64Avatar('${member['imageBase64']}', radius: 32))
                    : Icon(
                        occupied ? (muted ? Icons.mic_off : Icons.mic) : Icons.mic_none,
                        color: color,
                        size: 30,
                      ),
              ),
              if (occupied)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: muted ? Colors.redAccent : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(muted ? Icons.mic_off : Icons.mic, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            isMe ? 'أنت' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(role, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _messageBubble(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final message = doc.data();
    final user = FirebaseAuth.instance.currentUser;
    final bool isMe = message['userId'] == user?.uid;
    final type = '${message['type'] ?? 'text'}';
    final name = '${message['name'] ?? 'لاعب'}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.deepPurple.withOpacity(.35)
              : Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                isMe ? 'أنت' : name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.purpleAccent : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildBase64Image(message),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text('${message['text'] ?? ''}'),
              ),
          ],
        ),
      ),
    );
  }

  void _showMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151522),
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream: _membersRef.orderBy('joinedAt').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('أعضاء الروم', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...docs.map((d) {
                final m = d.data();
                final img = '${m['imageBase64'] ?? ''}';
                final role = '${m['role'] ?? 'عضو'}';
                final nick = '${m['nickname'] ?? 'لاعب'}';
                return Card(child: ListTile(
                  leading: img.isNotEmpty ? base64Avatar(img, radius: 24) : CircleAvatar(child: Text(nick.isNotEmpty ? nick.characters.first : 'ل')),
                  title: Text(nick),
                  subtitle: Text('${m['online'] == true ? '🟢 متصل' : '⚪ غير متصل'} • $role${m['onMic'] == true ? ' • 🎙️ على المايك' : ''}'),
                  trailing: _canManageRoom && d.id != FirebaseAuth.instance.currentUser?.uid
                      ? PopupMenuButton<String>(
                          onSelected: (v) => _memberAction(d.id, m, v),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'mic', child: Text('🎤 السماح/منع المايك')),
                            PopupMenuItem(value: 'mute', child: Text('🔇 كتم/فتح')),
                            PopupMenuItem(value: 'admin', child: Text('👑 تعيين مشرف')),
                            PopupMenuItem(value: 'kick', child: Text('🚫 طرد من الروم')),
                          ],
                        )
                      : null,
                ));
              }),
            ]);
          },
        ),
      ),
    );
  }

  Future<void> _memberAction(String uid, Map<String,dynamic> m, String action) async {
    try {
      final ref = _membersRef.doc(uid);
      if (action == 'mic') await ref.set({'micAllowed': !(m['micAllowed'] == false)}, SetOptions(merge:true));
      if (action == 'mute') await ref.set({'muted': !(m['muted'] == true)}, SetOptions(merge:true));
      if (action == 'admin') await ref.set({'role':'مشرف'}, SetOptions(merge:true));
      if (action == 'kick') await ref.set({'kicked':true,'online':false}, SetOptions(merge:true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final roomName = '${widget.data['name'] ?? 'الروم'}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
            if ('${widget.data['status'] ?? ''}'.isNotEmpty)
              Text('${widget.data['status']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(tooltip: 'الأعضاء', onPressed: () => _showMembers(), icon: const Icon(Icons.groups_rounded)),
          if (_canManageRoom) IconButton(tooltip: 'إدارة الروم', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomManagementPage(roomId: widget.roomId, data: widget.data))), icon: const Icon(Icons.settings_rounded)),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.025),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(.06)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.purpleAccent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'مايكات الروم',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_voiceLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '5 مايكات',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 105,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _membersRef.where('onMic', isEqualTo: true).snapshots(),
                    builder: (context, snap) {
                      final members = snap.data?.docs
                              .map((d) => d.data())
                              .where((m) => m['online'] != false)
                              .take(5)
                              .toList() ??
                          <Map<String, dynamic>>[];
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) =>
                            _micCard(index < members.length ? members[index] : null, index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _voiceLoading ? null : _toggleMic,
                      icon: Icon(_onMic ? Icons.mic : Icons.mic_none),
                      label: Text(_onMic ? 'نزل من المايك' : 'اصعد للمايك'),
                    ),
                    if (_onMic) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _toggleMute,
                        icon: Icon(
                          _micMuted ? Icons.mic_off : Icons.mic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesRef
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل رسائل الروم'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 55,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'دردشة الروم',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'اكتب رسالة أو أرسل صورة من الاستوديو',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollMessages());

                return ListView.builder(
                  controller: _messagesController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _messageBubble(docs[index]),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'إرسال صورة من الاستوديو',
                    onPressed: _imageUploading ? null : _pickAndSendImage,
                    icon: _imageUploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
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

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});
  @override State<CreateRoomPage> createState() => _CreateRoomPageState();
}
class _CreateRoomPageState extends State<CreateRoomPage> {
  final name=TextEditingController(); final status=TextEditingController(); final picker=ImagePicker();
  bool loading=false; String imageBase64='';
  @override void dispose(){name.dispose();status.dispose();super.dispose();}
  Future<void> create() async {
    final u=FirebaseAuth.instance.currentUser; if(u==null) return;
    if(name.text.trim().isEmpty){_toast('اكتب اسم الروم');return;}
    setState(()=>loading=true);
    try{
      final p=await FirebaseFirestore.instance.collection('users').doc(u.uid).get(); final pd=p.data()??{};
      final ref=await FirebaseFirestore.instance.collection('rooms').add({
        'name':name.text.trim(),'status':status.text.trim(),'coverBase64':imageBase64,
        'ownerId':u.uid,'ownerName':'${pd['nickname']??u.displayName??'المالك'}','membersCount':1,
        'createdAt':FieldValue.serverTimestamp(),'adminIds':[u.uid],
      });
      await ref.collection('members').doc(u.uid).set({'uid':u.uid,'nickname':'${pd['nickname']??'المالك'}','role':'المالك','online':true,'joinedAt':FieldValue.serverTimestamp()});
      if(mounted) Navigator.pop(context);
    }catch(e){_toast('تعذر إنشاء الروم: $e');}
    if(mounted)setState(()=>loading=false);
  }
  void _toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إنشاء روم')),body:ListView(padding:const EdgeInsets.all(16),children:[
    GestureDetector(onTap:()async{final x=await pickBase64Image(picker);if(x!=null)setState(()=>imageBase64=x);},child:Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),color:Colors.white10),child:imageBase64.isNotEmpty?ClipRRect(borderRadius:BorderRadius.circular(22),child:Image.memory(base64Decode(imageBase64),fit:BoxFit.cover)):const Icon(Icons.add_a_photo_outlined,size:50))),
    const SizedBox(height:14),TextField(controller:name,maxLength:30,decoration:const InputDecoration(labelText:'اسم الروم',prefixIcon:Icon(Icons.forum))),
    const SizedBox(height:10),TextField(controller:status,maxLength:60,decoration:const InputDecoration(labelText:'حالة الروم',hintText:'مثلاً: 🎤 دردشة صوتية الآن',prefixIcon:Icon(Icons.info_outline))),
    const SizedBox(height:18),SizedBox(height:52,child:FilledButton(onPressed:loading?null:create,child:loading?const CircularProgressIndicator():const Text('إنشاء الروم')))
  ]));
}

class RoomManagementPage extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> data;
  const RoomManagementPage({super.key, required this.roomId, required this.data});
  @override State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  late final TextEditingController name = TextEditingController(text: '${widget.data['name'] ?? ''}');
  late final TextEditingController status = TextEditingController(text: '${widget.data['status'] ?? ''}');
  final picker = ImagePicker();
  String image = '';
  bool loading = false;
  @override void initState() { super.initState(); image = '${widget.data['coverBase64'] ?? ''}'; }

  @override void dispose() { name.dispose(); status.dispose(); super.dispose(); }

  Future<void> save() async {
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({
        'name': name.text.trim(),
        'status': status.text.trim(),
        if (image.isNotEmpty) 'coverBase64': image,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ تعديل الروم')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> deleteRoom() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الروم'),
        content: const Text('متأكد تريد حذف الروم؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).delete();
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الروم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () async {
              final x = await pickBase64Image(picker);
              if (x != null) setState(() => image = x);
            },
            child: Container(
              height: 160,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white10),
              child: image.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(base64Decode(image), fit: BoxFit.cover))
                  : const Center(child: Icon(Icons.photo_camera_back_outlined, size: 50)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: name, maxLength: 30, decoration: const InputDecoration(labelText: 'اسم الروم', prefixIcon: Icon(Icons.edit))),
          const SizedBox(height: 12),
          TextField(controller: status, maxLength: 60, decoration: const InputDecoration(labelText: 'حالة الروم', hintText: 'مثلاً: 🎤 دردشة صوتية الآن', prefixIcon: Icon(Icons.info_outline))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: loading ? null : save, icon: const Icon(Icons.save), label: const Text('حفظ التعديلات')),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.groups), title: const Text('إدارة أعضاء الروم'), subtitle: const Text('مشرفين، مايك، كتم، طرد'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomMembersAdminPage(roomId: widget.roomId))))),
          Card(child: ListTile(leading: const Icon(Icons.delete_forever, color: Colors.redAccent), title: const Text('حذف الروم'), onTap: deleteRoom)),
        ],
      ),
    );
  }
}

class RoomMembersAdminPage extends StatelessWidget {
  final String roomId;
  const RoomMembersAdminPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('members');
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة أعضاء الروم')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(12),
            children: s.data!.docs.map((d) {
              final m = d.data();
              final img = '${m['imageBase64'] ?? ''}';
              return Card(
                child: ListTile(
                  leading: img.isNotEmpty ? base64Avatar(img) : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${m['nickname'] ?? 'لاعب'}'),
                  subtitle: Text('${m['role'] ?? 'عضو'} • ${m['online'] == true ? 'متصل' : 'غير متصل'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      final r = d.reference;
                      if (v == 'admin') await r.set({'role': 'مشرف'}, SetOptions(merge: true));
                      if (v == 'mic') await r.set({'micAllowed': !(m['micAllowed'] == false)}, SetOptions(merge: true));
                      if (v == 'mute') await r.set({'muted': !(m['muted'] == true)}, SetOptions(merge: true));
                      if (v == 'kick') await r.set({'kicked': true, 'online': false}, SetOptions(merge: true));
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'admin', child: Text('👑 تعيين مشرف')),
                      PopupMenuItem(value: 'mic', child: Text('🎤 منع/سماح المايك')),
                      PopupMenuItem(value: 'mute', child: Text('🔇 كتم/فتح')),
                      PopupMenuItem(value: 'kick', child: Text('🚫 طرد من الروم')),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool checking = true;
  bool allowed = false;
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final d = await currentUserData();
    if (mounted) setState(() { allowed = isAdminRole('${d['role'] ?? ''}'); checking = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!allowed) return const _SimplePage(title: 'لوحة الإدارة', icon: Icons.lock_outline, text: 'هذه الصفحة للأدمن فقط.');
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة الإدارة'), bottom: const TabBar(tabs: [Tab(text: 'المستخدمون'), Tab(text: 'الرومات'), Tab(text: 'النظام')])),
        body: const TabBarView(children: [AdminUsersTab(), AdminRoomsTab(), AdminSystemTab()]),
      ),
    );
  }
}

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(padding: const EdgeInsets.all(10), children: s.data!.docs.map((d) {
          final u = d.data(); final img = '${u['imageBase64'] ?? ''}';
          return Card(child: ListTile(
            leading: img.isNotEmpty ? base64Avatar(img) : const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${u['nickname'] ?? 'لاعب'}'),
            subtitle: Text('دور: ${u['role'] ?? 'user'} • نقاط: ${u['points'] ?? 0} • تاج: ${u['tag'] ?? ''}'),
            onTap: () => showDialog(context: context, builder: (_) => AdminUserDialog(userId: d.id, data: u)),
          ));
        }).toList());
      },
    );
  }
}

class AdminUserDialog extends StatefulWidget {
  final String userId; final Map<String, dynamic> data;
  const AdminUserDialog({super.key, required this.userId, required this.data});
  @override State<AdminUserDialog> createState() => _AdminUserDialogState();
}
class _AdminUserDialogState extends State<AdminUserDialog> {
  late final role = TextEditingController(text: '${widget.data['role'] ?? 'user'}');
  late final tag = TextEditingController(text: '${widget.data['tag'] ?? ''}');
  late final points = TextEditingController(text: '${widget.data['points'] ?? 0}');
  late final wallet = TextEditingController(text: '${widget.data['walletBalance'] ?? 0}');
  bool saving = false;
  bool banned = false;
  @override void initState() { super.initState(); banned = widget.data['banned'] == true; }
  @override void dispose() { role.dispose(); tag.dispose(); points.dispose(); wallet.dispose(); super.dispose(); }
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'role': role.text.trim(), 'tag': tag.text.trim(),
        'points': int.tryParse(points.text) ?? 0,
        'walletBalance': int.tryParse(wallet.text) ?? 0,
        'banned': banned,
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    if (mounted) setState(() => saving = false);
  }
  @override Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.data['nickname'] ?? 'مستخدم'}'),
    content: SingleChildScrollView(child: Column(children: [
      TextField(controller: role, decoration: const InputDecoration(labelText: 'الصلاحية (user/admin/superadmin)')),
      TextField(controller: tag, decoration: const InputDecoration(labelText: 'التاق')),
      TextField(controller: points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'النقاط')),
      TextField(controller: wallet, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رصيد المحفظة')),
      SwitchListTile(value: banned, onChanged: (v) => setState(() => banned = v), title: const Text('🚫 حظر الحساب'), contentPadding: EdgeInsets.zero),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: saving ? null : save, child: const Text('حفظ'))],
  );
}

class AdminRoomsTab extends StatelessWidget {
  const AdminRoomsTab({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('rooms').orderBy('createdAt', descending: true).snapshots(),
    builder: (context, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(10), children: s.data!.docs.map((d) {
        final r = d.data();
        return Card(
          child: ListTile(
            title: Text('${r['name'] ?? 'روم'}'),
            subtitle: Text('${r['status'] ?? ''} • المالك: ${r['ownerName'] ?? ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomManagementPage(roomId: d.id, data: r),
                ),
              ),
            ),
          ),
        );
      }).toList());
    },
  );
}


// ============================================================
// COMMON UI / NAVIGATION HELPERS
// ============================================================

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث عن لاعب أو روم...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'الأصدقاء',
      icon: Icons.group_outlined,
      text: 'قائمة الأصدقاء والطلبات راح تنربط هنا.',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white54)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(icon, size: 60, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
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
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}


// ============================================================
// BASIC HOME PAGES
// ============================================================

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎮 الألعاب', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.casino_outlined)),
              title: const Text('لودو', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('العب لودو أونلاين مع الأصدقاء'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _SimplePage(title: 'لودو', icon: Icons.grid_4x4_rounded, text: 'لعبة لودو أونلاين نكمل ربطها هنا.')),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _EmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'ألعاب أكثر قريباً',
            subtitle: 'راح نضيف الألعاب الجديدة تباعاً داخل مزاج.',
          ),
        ],
      ),
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _SimplePage(title: 'المحفظة', icon: Icons.account_balance_wallet_outlined, text: 'سجل الدخول أولاً.');

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('💰 المحفظة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};
          final balance = (data['walletBalance'] ?? 0) as num;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, size: 55),
                      const SizedBox(height: 12),
                      const Text('الرصيد الحالي', style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 6),
                      Text('${balance.toInt()} نقطة', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خدمة الشحن نكمل إعدادها قريباً'))),
                icon: const Icon(Icons.add_card),
                label: const Text('شحن الرصيد'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔔 الإشعارات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const _EmptyState(icon: Icons.notifications_none_rounded, title: 'ماكو إشعارات', subtitle: 'راح تظهر الإعلانات هنا.');
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
                  title: const Text('إعلان مزاج', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['text'] ?? ''}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminSystemTab extends StatelessWidget {
  const AdminSystemTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    _MenuTile(icon: Icons.campaign_outlined, title: 'الإعلانات', subtitle: 'إرسال إعلان عام', onTap: () => _announcement(context)),
    _MenuTile(icon: Icons.badge_outlined, title: 'التاقات والصلاحيات', subtitle: 'تعديلها من المستخدمين', onTap: () => DefaultTabController.of(context).animateTo(0)),
    _MenuTile(icon: Icons.mic_external_on_outlined, title: 'إدارة المايكات', subtitle: 'التحكم بمنع وسماح المايك داخل الروم', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ادخل إدارة الروم ثم الأعضاء')))),
  ]);
  static Future<void> _announcement(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('إعلان عام'), content: TextField(controller: c, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب الإعلان')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('نشر'))],
    ));
    if (ok == true && c.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('announcements').add({'text': c.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان')));
    }
  }
}

class _SimplePage extends StatelessWidget { final String title,text; final IconData icon; const _SimplePage({required this.title,required this.icon,required this.text}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(title)),body:Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:70,color:Theme.of(context).colorScheme.primary),const SizedBox(height:18),Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:16,color:Colors.white60))])))); }
