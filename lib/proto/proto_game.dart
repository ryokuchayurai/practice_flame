import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:practice_flame/a_star.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_layer.dart';

class ProtoGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final MainLayerComponent _mainLayerComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    collisionDetection =
        StandardCollisionDetection(broadphase: ProtoSweep<ShapeHitbox>());
    camera.viewport = FixedResolutionViewport(Vector2(400, 320));

    add(_mainLayerComponent = MainLayerComponent());
    add(MenuLayerComponent());

    camera.followComponent(_mainLayerComponent.player,
        worldBounds: const Rect.fromLTRB(0, 0, 16.0 * 50, 16.0 * 50));
    add(FpsTextComponent());
  }
}

class MapNode extends Object with Node<MapNode> {
  Vector2 position;
  Set<MapNode> connectedNodes = <MapNode>{};
  MapNode(this.position);
}

class MapGraph extends Graph<MapNode> {
  @override
  List<MapNode> allNodes = [];

  @override
  num getDistance(MapNode a, MapNode b) {
    return a.position.distanceTo(b.position);
  }

  @override
  num getHeuristicDistance(MapNode a, MapNode b) {
    return a.position.distanceTo(b.position);
  }

  @override
  Iterable<MapNode> getNeighboursOf(MapNode node) {
    return node.connectedNodes;
  }
}
