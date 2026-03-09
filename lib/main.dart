import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(GameWidget(game: MolkkyJamGame()));
}

class MolkkyJamGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // 背景（今はプレースホルダー）
    add(BackgroundComponent());
    
    // 主人公（ダミー）
    add(ProtagonistComponent());

    // 味方クリーチャー（わらわら動くデモ）
    for (int i = 0; i < 10; i++) {
      add(CreatureComponent());
    }
  }
}

class BackgroundComponent extends PositionComponent with HasGameRef {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      gameRef.size.toRect(),
      Paint()..color = Colors.green.shade900,
    );
  }
}

class ProtagonistComponent extends PositionComponent with HasGameRef {
  ProtagonistComponent() : super(size: Vector2(64, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = gameRef.size / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      (size / 2).toOffset(),
      size.x / 2,
      Paint()..color = Colors.red,
    );
    // メガネとキャップのつもり
    canvas.drawRect(Rect.fromLTWH(0, 10, size.x, 10), Paint()..color = Colors.black);
  }
}

class CreatureComponent extends PositionComponent with HasGameRef {
  late Vector2 velocity;
  final _random = Random();

  CreatureComponent() : super(size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(
      _random.nextDouble() * gameRef.size.x,
      _random.nextDouble() * gameRef.size.y,
    );
    velocity = Vector2(
      (_random.nextDouble() - 0.5) * 100,
      (_random.nextDouble() - 0.5) * 100,
    );
  }

  @override
  void update(double dt) {
    position += velocity * dt;

    // 画面端で跳ね返る（わらわら感）
    if (position.x < 0 || position.x > gameRef.size.x) velocity.x *= -1;
    if (position.y < 0 || position.y > gameRef.size.y) velocity.y *= -1;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }
}
