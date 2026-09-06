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
