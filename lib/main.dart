import 'package:flutter/material.dart';
import 'models/game_models.dart';
import 'logic/game_logic.dart';
import 'three_d_demo_screen.dart';
import 'three_d_world_layer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MolkkyJamApp());
}

class MolkkyJamApp extends StatelessWidget {
  const MolkkyJamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molkky JAM',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const MainGameMenu(),
    );
  }
}

class MainGameMenu extends StatefulWidget {
  const MainGameMenu({super.key});

  @override
  State<MainGameMenu> createState() => _MainGameMenuState();
}

class _MainGameMenuState extends State<MainGameMenu> {
  final List<Player> _players = [
    Player(id: '1', name: 'Nori-kun', initialOrder: 0),
    Player(id: '2', name: 'Micchan', initialOrder: 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Molkky JAM')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Main Menu', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final match = MolkkyMatch(
                  players: _players.map((p) {
                    p.resetForNewSet();
                    p.setsWon = 0;
                    p.setFinalScores = [];
                    p.matchScoreHistory = [];
                    return p;
                  }).toList(),
                  limit: 1,
                  type: MatchType.fixedSets,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => GameScreen(match: match),
                  ),
                );
              },
              child: const Text('Start 1-Set Match'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThreeDDemoScreen()),
                );
              },
              child: const Text('Open 3D Demo (WIP)'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final MolkkyMatch match;
  const GameScreen({super.key, required this.match});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentPlayerIndex = 0;
  List<int> selectedSkitels = [];
  bool isSetFinished = false;

  void _onSkitelTap(int num) {
    if (isSetFinished) return;
    setState(() {
      if (selectedSkitels.contains(num)) {
        selectedSkitels.remove(num);
      } else {
        selectedSkitels.add(num);
      }
    });
  }

  void _submitThrow() {
    if (isSetFinished) return;
    final player = widget.match.players[currentPlayerIndex];
    setState(() {
      GameLogic.processThrow(player, selectedSkitels, widget.match);
      
      if (player.currentScore == widget.match.targetScore) {
        isSetFinished = true;
        player.setsWon++;
        _showWinnerDialog(player);
      } else {
        selectedSkitels.clear();
        _nextPlayer();
      }
    });
  }

  void _nextPlayer() {
    int start = currentPlayerIndex;
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.match.players.length;
    } while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex != start);
  }

  void _showWinnerDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Winner!'),
        content: Text('${winner.name} wins this set!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.match.players[currentPlayerIndex];
    
    return Scaffold(
      body: Stack(
        children: [
          const ThreeDWorldLayer(creatureCount: 10),
          
          // Score Overlay
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: widget.match.players.map((p) => Column(
                  children: [
                    Text(p.name, style: TextStyle(
                      fontWeight: p == currentPlayer ? FontWeight.bold : FontWeight.normal,
                      color: p == currentPlayer ? Colors.orange : Colors.white,
                    )),
                    Text('${p.currentScore} / 50', style: const TextStyle(fontSize: 20)),
                    if (p.isDisqualified) const Text('DQ', style: TextStyle(color: Colors.red)),
                  ],
                )).toList(),
              ),
            ),
          ),

          // Controls Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Turn: ${currentPlayer.name}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (c, i) {
                      final num = i + 1;
                      final isSelected = selectedSkitels.contains(num);
                      return ElevatedButton(
                        onPressed: () => _onSkitelTap(num),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: isSelected ? Colors.orange : Colors.grey[800],
                        ),
                        child: Text('$num'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitThrow,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(selectedSkitels.isEmpty ? 'Miss (0 pts)' : 'Confirm (${selectedSkitels.length == 1 ? selectedSkitels.first : selectedSkitels.length} pts)'),
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

