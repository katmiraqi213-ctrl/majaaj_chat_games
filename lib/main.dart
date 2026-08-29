import 'package:flutter/material.dart';

void main() {
  runApp(const MazaajApp());
}

class MazaajApp extends StatelessWidget {
  const MazaajApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزاج',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    ChatPage(),
    GamesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مزاج 💜',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),

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
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat),
            label: 'الدردشة',
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

// =======================
// صفحة الدردشة
// =======================

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController =
      TextEditingController();

  final List<String> messages = [
    'هلا بالجميع 👋',
    'نورتوا تطبيق مزاج 💜',
    'منو جاهز للعب؟ 🎮',
  ];

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add(messageController.text.trim());
      messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: const Text(
                    'مستخدم',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(messages[index]),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: OutlineInputBorder(),
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
      ],
    );
  }
}

// =======================
// صفحة الألعاب
// =======================

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الألعاب 🎮',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        GameCard(
          icon: '❌⭕',
          title: 'X / O',
          subtitle: 'لعبة إكس أو',
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
          icon: '🃏',
          title: 'UNO',
          subtitle: 'قريباً',
          onTap: () {
            showComingSoon(context);
          },
        ),

        GameCard(
          icon: '🎱',
          title: 'كيرم',
          subtitle: 'قريباً',
          onTap: () {
            showComingSoon(context);
          },
        ),
      ],
    );
  }

  void showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه اللعبة ستتوفر قريباً 🔥'),
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: Text(
          icon,
          style: const TextStyle(fontSize: 35),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),

        onTap: onTap,
      ),
    );
  }
}

// =======================
// صفحة الحساب
// =======================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person,
              size: 55,
            ),
          ),

          SizedBox(height: 15),

          Text(
            'محمد',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'النقاط ⭐ 0',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// =======================
// لعبة X O
// =======================

class XOGame extends StatefulWidget {
  const XOGame({super.key});

  @override
  State<XOGame> createState() => _XOGameState();
}

class _XOGameState extends State<XOGame> {
  List<String> board = List.filled(9, '');

  String player = 'X';
  String winner = '';

  void play(int index) {
    if (board[index].isNotEmpty || winner.isNotEmpty) {
      return;
    }

    setState(() {
      board[index] = player;

      if (checkWinner(player)) {
        winner = player;
      } else if (!board.contains('')) {
        winner = 'تعادل';
      } else {
        player = player == 'X' ? 'O' : 'X';
      }
    });
  }

  bool checkWinner(String p) {
    const combinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final combination in combinations) {
      if (board[combination[0]] == p &&
          board[combination[1]] == p &&
          board[combination[2]] == p) {
        return true;
      }
    }

    return false;
  }

  void resetGame() {
    setState(() {
      board = List.filled(9, '');
      player = 'X';
      winner = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X / O 🎮'),
      ),

      body: Column(
        children: [
          const SizedBox(height: 25),

          Text(
            winner.isEmpty
                ? 'الدور: $player'
                : winner == 'تعادل'
                    ? 'تعادل 🤝'
                    : 'الفائز: $winner 🎉',

            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(25),
              itemCount: 9,

              gridDelegate:
                  const SliverGridDelegat
