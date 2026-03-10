import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebaseの初期化は後で行うため、一旦コメントアウト
  // try { await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); } catch (e) {}
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
      ),
      // 認証を一旦スキップして直接ゲームメニューへ進むように変更
      home: const MainGameMenu(),
    );
  }
}

// 認証チェック画面（現在は不使用だが、将来のために保持）
class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 常にログイン済みとして扱うか、直接遷移させる
    return const MainGameMenu();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    // 実装は後ほど
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login feature is coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Molkky JAM',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: () => _signInWithGoogle(context),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainGameMenu extends StatelessWidget {
  const MainGameMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Molkky JAM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // ログアウト処理（現在は単にメッセージ表示）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guest user cannot logout.')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GameWidget(game: MolkkyJamGame()),
          const Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: Guest Player',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Forest Stage: Tap to Move',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MolkkyJamGame extends FlameGame with TapDetector {
  late ProtagonistComponent protagonist;

  @override
  Future<void> onLoad() async {
    add(BackgroundComponent());
    protagonist = ProtagonistComponent(characterName: 'boy_full.png');
    add(protagonist);

    for (int i = 0; i < 5; i++) {
      add(MushroomComponent());
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    protagonist.targetPosition = info.eventPosition.global;
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

class ProtagonistComponent extends SpriteComponent with HasGameRef {
  Vector2? targetPosition;
  final double speed = 300.0;

  ProtagonistComponent({required String characterName})
      : super(size: Vector2(150, 200), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(characterName);
    position = gameRef.size / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = targetPosition;
    if (target != null) {
      Vector2 direction = target - position;
      if (direction.length < 5) {
        position = target;
        targetPosition = null;
      } else {
        position += direction.normalized() * speed * dt;
      }
    }
  }
}

class MushroomComponent extends SpriteComponent with HasGameRef {
  final _random = Random();

  MushroomComponent() : super(size: Vector2(30, 30), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('mushroom_creature.png');
    position = Vector2(
      _random.nextDouble() * gameRef.size.x,
      _random.nextDouble() * gameRef.size.y,
    );
  }
}
