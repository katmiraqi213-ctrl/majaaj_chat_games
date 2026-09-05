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
            label: const Text('لعب مرة ثانية'),
          ),
        ],
      );
    }

    if (status == 'finished') {
      final winnerId = data['winnerId'] ?? '';

      final winnerName =
          winnerId == data['playerXId']
              ? data['playerXNickname'] ?? 'اللاعب X'
              : data['playerONickname'] ?? 'اللاعب O';

      final user = FirebaseAuth.instance.currentUser;

      final isMe = winnerId == user?.uid;

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
            onPressed: () => rematch(data),
            icon: const Icon(Icons.refresh),
            label: const Text('لعب مرة ثانية'),
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

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'المباراة غير موجودة',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          final board = List<String>.from(
            (data['board'] ?? List<String>.filled(9, ''))
                .map((e) => e.toString()),
          );

          final user =
              FirebaseAuth.instance.currentUser;

          final playerXId = data['playerXId'];
          final playerOId = data['playerOId'];
          final turn = data['turn'];
          final status = data['status'];

          final mySymbol =
              user?.uid == playerXId
                  ? 'X'
                  : user?.uid == playerOId
                      ? 'O'
                      : '';

          final turnName =
              turn == playerXId
                  ? data['playerXNickname'] ??
                      'اللاعب X'
                  : turn == playerOId
                      ? data['playerONickname'] ??
                          'اللاعب O'
                      : '';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${data['playerXNickname'] ?? 'X'}  ❌  ضد  ⭕  ${data['playerONickname'] ?? 'O'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (status == 'playing')
                    Text(
                      turn == user?.uid
                          ? '🎯 دورك'
                          : '⏳ دور $turnName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                    itemBuilder: (context, index) {
                      final value = board[index];

                      return InkWell(
                        onTap:
                            status == 'playing' &&
                                    turn == user?.uid &&
                                    value.isEmpty &&
                                    mySymbol.isNotEmpty
                                ? () => playMove(
                                      index,
                                      data,
                                    )
                                : null,
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(16),
                            color: Colors.grey.shade900,
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: value == 'X'
                                    ? Colors.redAccent
                                    : Colors.blueAccent,
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حسابي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snapshot.data ?? {};

          final nickname =
              data['nickname'] ??
              user?.email?.split('@').first ??
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
            padding: const EdgeInsets.all(20),
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
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Center(
                child: Text(
                  email.toString(),
                  style: const TextStyle(
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
                            const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              points.toString(),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const Text('النقاط'),
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
                            const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              level.toString(),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const Text('المستوى'),
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
                  leading: const Icon(
                    Icons.logout,
                  ),
                  title: const Text(
                    'تسجيل الخروج',
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance
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
