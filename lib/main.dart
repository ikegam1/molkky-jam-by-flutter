import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: MolkkyJamGame()),
            const Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Molkky JAM: Forest Stage (Sunset Horror)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MolkkyJamGame extends FlameGame with TapDetector {
  late ProtagonistComponent protagonist;
  bool isBoy = true;

  @override
  Future<void> onLoad() async {
    // 背景グラフィック
    add(BackgroundComponent());
    
    // 主人公
    protagonist = ProtagonistComponent(characterName: 'boy_full.png');
    add(protagonist);

    // エリンギ人間（わらわら動くデモ）
    for (int i = 0; i < 20; i++) {
      add(CreatureComponent(imageName: 'mushroom_creature.png'));
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (info.eventPosition.global.y < 150) {
      isBoy = !isBoy;
      protagonist.switchCharacter(isBoy ? 'boy_full.png' : 'girl_full.png');
      return;
    }
    protagonist.targetPosition = info.eventPosition.global;
  }
}

class BackgroundComponent extends SpriteComponent with HasGameRef {
  BackgroundComponent() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('forest_background.png');
    // 画面全体を覆うようにサイズを調整
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

  ProtagonistComponent({required String characterName}) : super(size: Vector2(150, 200), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(characterName);
    position = gameRef.size / 2;
  }

  void switchCharacter(String characterName) async {
    sprite = await gameRef.loadSprite(characterName);
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

class CreatureComponent extends SpriteComponent with HasGameRef {
  late Vector2 velocity;
  final _random = Random();
  final String imageName;

  CreatureComponent({required this.imageName}) : super(size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(imageName);
    position = Vector2(
      _random.nextDouble() * gameRef.size.x,
      _random.nextDouble() * gameRef.size.y,
    );
    velocity = Vector2(
      (_random.nextDouble() - 0.5) * 60,
      (_random.nextDouble() - 0.5) * 60,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.x < 0 || position.x > gameRef.size.x) velocity.x *= -1;
    if (position.y < 0 || position.y > gameRef.size.y) velocity.y *= -1;
  }
}
