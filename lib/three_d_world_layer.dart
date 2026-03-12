import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDWorldLayer extends StatefulWidget {
  const ThreeDWorldLayer({
    super.key,
    this.creatureCount = 10,
    this.showTopStatus = false,
  });

  final int creatureCount;
  final bool showTopStatus;

  @override
  State<ThreeDWorldLayer> createState() => _ThreeDWorldLayerState();
}

class _ThreeDWorldLayerState extends State<ThreeDWorldLayer> {
  final _random = Random();
  late final List<_Mover> movers;
  Timer? _loop;

  // model_viewer は Flutter Web の場合、assets 配下が assets/assets/ で配信されるためこのURLを使用
  static const String localEringiModel = 'assets/assets/models/eringi_human.glb';
  static const String fallbackModel =
      'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
  static const bool useLocalModel = true;

  @override
  void initState() {
    super.initState();
    movers = List.generate(widget.creatureCount, (i) => _Mover(seed: i + 1));
    _loop = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick(0.033));
  }

  void _tick(double dt) {
    if (!mounted) return;

    for (int i = 0; i < movers.length; i++) {
      final me = movers[i];

      double sepX = 0, sepY = 0, cohX = 0, cohY = 0;
      int near = 0;

      for (int j = 0; j < movers.length; j++) {
        if (i == j) continue;
        final other = movers[j];
        final dx = me.x - other.x;
        final dy = me.y - other.y;
        final d2 = dx * dx + dy * dy;

        if (d2 < 0.02) {
          sepX += dx;
          sepY += dy;
        }
        if (d2 < 0.08) {
          cohX += other.x;
          cohY += other.y;
          near++;
        }
      }

      if (near > 0) {
        cohX = (cohX / near) - me.x;
        cohY = (cohY / near) - me.y;
      }

      me.vx += sepX * 0.20 + cohX * 0.02 + (_random.nextDouble() - 0.5) * 0.014;
      me.vy += sepY * 0.20 + cohY * 0.02 + (_random.nextDouble() - 0.5) * 0.014;

      final speed = sqrt(me.vx * me.vx + me.vy * me.vy);
      const maxSpeed = 0.22;
      if (speed > maxSpeed) {
        me.vx = me.vx / speed * maxSpeed;
        me.vy = me.vy / speed * maxSpeed;
      }

      me.x += me.vx * dt;
      me.y += me.vy * dt;

      if (me.x < 0.06 || me.x > 0.94) me.vx *= -1;
      if (me.y < 0.34 || me.y > 0.95) me.vy *= -1;

      me.x = me.x.clamp(0.06, 0.94);
      me.y = me.y.clamp(0.34, 0.95);

      me.bob += dt * (2.0 + me.gaitSpeed);
      me.gaitPhase += dt * me.gaitSpeed * 3.0;
      me.heading = atan2(me.vy, me.vx);
      me.renderHeading = _lerpAngle(me.renderHeading, me.heading, 0.14);
    }

    setState(() {});
  }

  double _lerpAngle(double a, double b, double t) {
    var d = b - a;
    while (d > pi) d -= 2 * pi;
    while (d < -pi) d += 2 * pi;
    return a + d * t;
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/forest_background.png', fit: BoxFit.cover),
        ),
        ...movers.map((m) {
          final depthScale = (0.55 + m.y * 0.75) * m.bodyScale;
          final bob = sin(m.bob) * (2.0 + m.bodyScale * 2.0);
          final headingDeg = (m.renderHeading * 180 / pi) + 90;
          final walkPitchDeg = sin(m.gaitPhase) * 11.0;
          final walkRollDeg = cos(m.gaitPhase) * 4.0;

          return Align(
            alignment: Alignment(m.x * 2 - 1, m.y * 2 - 1),
            child: Transform.translate(
              offset: Offset(0, bob),
              child: SizedBox(
                width: 78 * depthScale,
                height: 78 * depthScale,
                child: IgnorePointer(
                  child: ModelViewer(
                    src: useLocalModel ? localEringiModel : fallbackModel,
                    relatedCss: '''
                    model-viewer{background-color:transparent;}
                    ''',
                    alt: 'Eringi 3D Creature',
                    cameraControls: false,
                    autoRotate: false,
                    disableZoom: true,
                    disablePan: true,
                    ar: false,
                    autoPlay: true,
                    backgroundColor: Colors.transparent,
                    loading: Loading.eager,
                    cameraOrbit: '0deg 78deg 2.0m',
                    orientation:
                        '${walkPitchDeg.toStringAsFixed(1)}deg ${headingDeg.toStringAsFixed(1)}deg ${walkRollDeg.toStringAsFixed(1)}deg',
                  ),
                ),
              ),
            ),
          );
        }),
        if (widget.showTopStatus)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: const Text(
                '3D World: 群れ徘徊 + 向き連動(進行方向) + 疑似歩行アニメ\n※ assets/models/eringi_human.glb を使用中',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _Mover {
  _Mover({required this.seed}) {
    final r = Random(seed);
    x = 0.1 + r.nextDouble() * 0.8;
    y = 0.4 + r.nextDouble() * 0.5;
    vx = (r.nextDouble() - 0.5) * 0.12;
    vy = (r.nextDouble() - 0.5) * 0.12;
    bob = r.nextDouble() * pi * 2;
    heading = atan2(vy, vx);
    renderHeading = heading;
    gaitPhase = r.nextDouble() * pi * 2;
    gaitSpeed = 1.4 + r.nextDouble() * 1.8;
    bodyScale = 0.85 + r.nextDouble() * 0.45;
  }

  final int seed;
  late double x, y, vx, vy, bob, heading, renderHeading;
  late double gaitPhase;
  late double gaitSpeed;
  late double bodyScale;
}
