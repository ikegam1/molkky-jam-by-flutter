import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDDemoScreen extends StatefulWidget {
  const ThreeDDemoScreen({super.key});

  @override
  State<ThreeDDemoScreen> createState() => _ThreeDDemoScreenState();
}

class _ThreeDDemoScreenState extends State<ThreeDDemoScreen> {
  final _random = Random();
  final List<_Mover> movers = List.generate(12, (i) => _Mover(seed: i + 1));
  Timer? _loop;

  @override
  void initState() {
    super.initState();
    _loop = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick(0.033));
  }

  void _tick(double dt) {
    if (!mounted) return;

    for (int i = 0; i < movers.length; i++) {
      final me = movers[i];

      // 軽い群れ行動（分離 + 少しだけ結合）
      double sepX = 0;
      double sepY = 0;
      double cohX = 0;
      double cohY = 0;
      int nearCount = 0;

      for (int j = 0; j < movers.length; j++) {
        if (i == j) continue;
        final other = movers[j];
        final dx = me.x - other.x;
        final dy = me.y - other.y;
        final dist2 = dx * dx + dy * dy;
        if (dist2 < 0.02) {
          sepX += dx;
          sepY += dy;
        }
        if (dist2 < 0.08) {
          cohX += other.x;
          cohY += other.y;
          nearCount++;
        }
      }

      if (nearCount > 0) {
        cohX = (cohX / nearCount) - me.x;
        cohY = (cohY / nearCount) - me.y;
      }

      me.vx += (sepX * 0.20 + cohX * 0.02 + (_random.nextDouble() - 0.5) * 0.015);
      me.vy += (sepY * 0.20 + cohY * 0.02 + (_random.nextDouble() - 0.5) * 0.015);

      // 速度制限
      final speed = sqrt(me.vx * me.vx + me.vy * me.vy);
      const maxSpeed = 0.24;
      if (speed > maxSpeed) {
        me.vx = (me.vx / speed) * maxSpeed;
        me.vy = (me.vy / speed) * maxSpeed;
      }

      me.x += me.vx * dt;
      me.y += me.vy * dt;

      // 境界反射
      if (me.x < 0.06) {
        me.x = 0.06;
        me.vx *= -1;
      } else if (me.x > 0.94) {
        me.x = 0.94;
        me.vx *= -1;
      }
      if (me.y < 0.34) {
        me.y = 0.34;
        me.vy *= -1;
      } else if (me.y > 0.95) {
        me.y = 0.95;
        me.vy *= -1;
      }

      me.bob += dt * (2.5 + me.seed * 0.03);
      me.heading = atan2(me.vy, me.vx);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Mushroom Demo (WIP)')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/forest_background.png', fit: BoxFit.cover),
          ),
          ...movers.map((m) {
            final depthScale = 0.55 + m.y * 0.75;
            final bob = sin(m.bob) * 4;
            return Align(
              alignment: Alignment(m.x * 2 - 1, m.y * 2 - 1),
              child: Transform.translate(
                offset: Offset(0, bob),
                child: SizedBox(
                  width: 80 * depthScale,
                  height: 80 * depthScale,
                  child: Transform.rotate(
                    angle: m.heading,
                    child: IgnorePointer(
                      child: ModelViewer(
                        // 仮3Dモデル（次でエリンギ人間.glbへ差し替え）
                        src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                        alt: '3D Creature',
                        cameraControls: false,
                        autoRotate: false,
                        disableZoom: true,
                        disablePan: true,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: const Text(
                '進捗: 3Dモデル複数体 + 群れっぽい徘徊AI + 斜め移動対応（WIP）\n次: エリンギ人間GLB差し替え / 向き連動の強化 / スコア画面統合',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mover {
  _Mover({required this.seed}) {
    final r = Random(seed);
    x = 0.1 + r.nextDouble() * 0.8;
    y = 0.4 + r.nextDouble() * 0.5;
    vx = (r.nextDouble() - 0.5) * 0.15;
    vy = (r.nextDouble() - 0.5) * 0.15;
    bob = r.nextDouble() * pi * 2;
    heading = 0;
  }

  final int seed;
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double bob;
  late double heading;
}
