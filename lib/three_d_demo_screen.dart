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
  final List<_Mover> movers = List.generate(6, (i) => _Mover(seed: i + 1));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        for (final m in movers) {
          m.x = 0.05 + _random.nextDouble() * 0.85;
          m.y = 0.30 + _random.nextDouble() * 0.60;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            return AnimatedAlign(
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeInOut,
              alignment: Alignment(m.x * 2 - 1, m.y * 2 - 1),
              child: SizedBox(
                width: 110,
                height: 110,
                child: IgnorePointer(
                  child: ModelViewer(
                    // 仮3Dモデル（後でエリンギ人間.glbへ差し替え）
                    src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                    alt: '3D Creature',
                    cameraControls: false,
                    autoRotate: true,
                    autoRotateDelay: 0,
                    rotationPerSecond: '50deg',
                    disableZoom: true,
                    disablePan: true,
                    backgroundColor: Colors.transparent,
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
                '進捗: 本物の3D描画エンジン導入完了。\n次: エリンギ人間のglbを作成して差し替え + 3D空間移動へ移行。',
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
  _Mover({required int seed}) {
    final r = Random(seed);
    x = 0.1 + r.nextDouble() * 0.8;
    y = 0.35 + r.nextDouble() * 0.55;
  }

  late double x;
  late double y;
}
