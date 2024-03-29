import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_layer.dart';
import 'package:practice_flame/proto/proto_text_component.dart';
import 'package:practice_flame/proto/status.dart';

class ProtoGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  MainLayerComponent? _mainLayerComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    collisionDetection =
        StandardCollisionDetection(broadphase: ProtoSweep<ShapeHitbox>());
    camera.viewport = FixedResolutionViewport(Vector2(400, 320));

    _createLayers();
    _addDebugInfo();

    if (_mainLayerComponent != null) {
      camera.followComponent(_mainLayerComponent!.player,
          worldBounds: const Rect.fromLTRB(0, 0, 16.0 * 50, 16.0 * 50));
    }
  }

  void _createLayers() {
    add(_mainLayerComponent = MainLayerComponent());
    add(MenuLayerComponent());
    add(HudLayerComponent());
    add(GameOverLayerComponent());

    // add(CutsceneLayerComponent());
  }

  void _addDebugInfo() {
    add(FpsTextComponent<TextPaint>(
        textRenderer: TextPaint(style: const TextStyle(fontSize: 8))));

    if (_mainLayerComponent != null) {
      add(ProtoTextComponent(
          () => '${_mainLayerComponent?.children.length} components',
          position: Vector2(0, 8),
          updateInterval: 1.0,
          textRenderer: TextPaint(style: const TextStyle(fontSize: 8)))
        ..priority = double.maxFinite.toInt()
        ..positionType = PositionType.viewport);
    }
  }

  void reset() {
    removeAll(children);

    _createLayers();
    _addDebugInfo();

    gameStatus.mode = GameMode.main;

    if (_mainLayerComponent != null) {
      camera.followComponent(_mainLayerComponent!.player,
          worldBounds: const Rect.fromLTRB(0, 0, 16.0 * 50, 16.0 * 50));
    }
  }

  void showPoint(Vector2 pos, {Color color = Colors.white}) {
    add(
      ParticleSystemComponent(
        priority: 1000,
        position: pos,
        particle: Particle.generate(
          count: 1,
          lifespan: 3,
          generator: (i) {
            return CircleParticle(
              radius: 1,
              paint: Paint()..color = color,
            );
          },
        ),
      ),
    );
  }
}
