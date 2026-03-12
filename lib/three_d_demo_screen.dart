import 'package:flutter/material.dart';

import 'three_d_world_layer.dart';

class ThreeDDemoScreen extends StatelessWidget {
  const ThreeDDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ThreeDWorldLayer(
        creatureCount: 12,
        showTopStatus: true,
      ),
    );
  }
}
