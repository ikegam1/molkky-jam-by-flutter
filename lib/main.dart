import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'models/game_models.dart';
import 'logic/game_logic.dart';
import 'three_d_demo_screen.dart';

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
  late MolkkyJamGame game;

  @override
  void initState() {
    super.initState();
    game = MolkkyJamGame();
  }

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
          // Flame Game Background
          GameWidget(game: game),
          
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

class MolkkyJamGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    add(BackgroundComponent());

    // 固定配置: 毒キノコ 5本
    for (int i = 0; i < 5; i++) {
      add(PoisonMushroomComponent());
    }

    // わらわら移動: 3D風キノコ人間
    for (int i = 0; i < 14; i++) {
      add(MushroomHuman3DComponent());
    }
  }
}

class BackgroundComponent extends SpriteComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('forest_background.png');
    size = gameRef.size;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }
}

class PoisonMushroomComponent extends SpriteComponent with HasGameRef {
  final _random = Random();

  PoisonMushroomComponent() : super(size: Vector2(24, 24), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('mushroom_creature.png');
    // 画面下寄りに固定配置（地面っぽく）
    position = Vector2(
      20 + _random.nextDouble() * (gameRef.size.x - 40),
      gameRef.size.y * (0.65 + _random.nextDouble() * 0.30),
    );
    opacity = 0.9;
  }
}

class MushroomHuman3DComponent extends PositionComponent with HasGameRef {
  final _random = Random();
  late SpriteComponent body;
  late CircleComponent shadow;
  late Vector2 velocity;
  late double baseY;
  double bobTime = 0;

  MushroomHuman3DComponent() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    baseY = 80 + _random.nextDouble() * (gameRef.size.y - 200);
    position = Vector2(
      40 + _random.nextDouble() * (gameRef.size.x - 80),
      baseY,
    );

    // Yが下ほど少し大きく見せて擬似3D感
    final depthScale = 0.65 + (position.y / gameRef.size.y) * 0.55;
    size = Vector2(42, 58) * depthScale;

    shadow = CircleComponent(
      radius: size.x * 0.22,
      paint: Paint()..color = Colors.black.withOpacity(0.30),
      anchor: Anchor.center,
      position: Vector2(size.x * 0.5, size.y * 0.95),
    );
    add(shadow);

    body = SpriteComponent(
      sprite: await gameRef.loadSprite('mushroom_human_3d.png'),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(body);

    velocity = Vector2(
      (_random.nextDouble() - 0.5) * 45,
      (_random.nextDouble() - 0.5) * 32,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    bobTime += dt * (1.5 + _random.nextDouble() * 0.2);
    final bobOffset = sin(bobTime * 3.0) * 2.8;

    position += velocity * dt;

    if (position.x < 12 || position.x > gameRef.size.x - 12) velocity.x *= -1;
    if (position.y < gameRef.size.y * 0.35 || position.y > gameRef.size.y * 0.93) velocity.y *= -1;

    // 深度スケーリングを毎フレーム更新
    final depthScale = 0.65 + (position.y / gameRef.size.y) * 0.55;
    final targetSize = Vector2(42, 58) * depthScale;
    size = targetSize;
    body.size = targetSize;
    body.position = targetSize / 2 + Vector2(0, bobOffset);

    shadow.radius = targetSize.x * 0.22;
    shadow.position = Vector2(targetSize.x * 0.5, targetSize.y * 0.95);
    shadow.scale = Vector2.all(1.0 - (bobOffset.abs() / 20));
  }
}
