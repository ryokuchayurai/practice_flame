import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:practice_flame/human1.dart';
import 'package:practice_flame/monster.dart';
import 'package:tiled/tiled.dart';

import 'a_star.dart';

class MapGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final v1 = Vector2(100, 100);
    final v2 = Vector2(200, 100);
    debugPrint('angleToSigned: ${v1.angleTo(v2) * radians2Degrees}');

    camera.viewport = FixedResolutionViewport(Vector2(400, 320));

    final tiledMap = await TiledComponent.load('danchi.tmx', Vector2.all(16));
    tiledMap.tileMap.setLayerVisibility(0, true);
    tiledMap.tileMap.setLayerVisibility(1, true);
    tiledMap.tileMap.setLayerVisibility(2, false);
    add(tiledMap);

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;
    final objGroup = tiledMap.tileMap.getLayer<ObjectGroup>('collision');
    for (final obj in objGroup!.objects) {
      // debugPrint('${obj.x} ${obj.y}');
      add(
        PositionComponent(position: Vector2(obj.x, obj.y), children: [
          RectangleHitbox(
            // position: Vector2(obj.x, obj.y),
            size: Vector2(obj.width, obj.height),
          )
            ..paint = hitboxPaint
            ..renderShape = true,
        ]),
      );
    }

    final tiledMapPassable =
        await TiledComponent.load('danchi.tmx', Vector2.all(16));
    tiledMapPassable.tileMap.setLayerVisibility(0, false);
    tiledMapPassable.tileMap.setLayerVisibility(1, false);
    tiledMapPassable.tileMap.setLayerVisibility(2, true);
    tiledMapPassable.priority = 100;
    add(tiledMapPassable);

    final human = Human();
    add(human);

    camera.followComponent(human,
        worldBounds: Rect.fromLTRB(0, 0, 100 * 16, 100 * 16));

    // add(RectangleComponent(
    //     position: Vector2.zero(),
    //     size: Vector2(4000, 3000),
    //     priority: 10000,
    //     paint: Paint()..color = Colors.black.withOpacity(0.3)));

    double x = 10;
    double y = 100;
    for (final bm in BlendMode.values) {
      add(TextComponent(
          text: '${bm.toString()}',
          position: Vector2(x, y),
          textRenderer: TextPaint(style: TextStyle(fontSize: 8))));
      add(CircleComponent(
          position: Vector2(x, y),
          radius: 10,
          priority: 10001,
          paint: Paint()
            ..color = Colors.black.withOpacity(0.1)
            ..blendMode = bm));
      x += 100;
    }

    add(FpsTextComponent());

    final rnd = Random();
    for (int i = 0; i < 0; i++) {
      final s = rnd.nextDouble() * 3;
      add(Monster(human)
        ..position = Vector2(rnd.nextDouble() * 1600, rnd.nextDouble() * 1600)
        ..scale = Vector2(s, s));
    }

    final blocktile = tiledMap.tileMap.getLayer<TileLayer>('block');
    List<TileNode> allNodes = [];
    List<List<TileNode?>?> map = []..length = 100;
    for (int y = 0; y < 100; y++) {
      map[y] = []..length = 100;
      final row = blocktile!.tileData![y];
      for (int x = 0; x < 100; x++) {
        final grid = row[x];
        if (grid.tile != 0) continue;
        final node = TileNode(Vector2(x * 16, y * 16));
        allNodes.add(node);
        map[y]![x] = node;
      }
    }

    for (int y = 0; y < 100; y++) {
      for (int x = 0; x < 100; x++) {
        final node = map[y]![x];
        if (node == null) {
          debugPrint('uoooo');
          continue;
        }

        for (var i = y - 1; i <= y + 1; i++) {
          if (i < 0 || i >= 100) {
            continue; // Outside Maze bounds.
          }
          for (var j = x - 1; j <= x + 1; j++) {
            if (j < 0 || j >= 100) {
              continue; // Outside Maze bounds.
            }
            if (i == y && j == x) {
              continue; // Same tile.
            }
            if (i != y && j != x) {
              continue; // namae nashi!
            }
            if (map[i]![j] == null) continue;
            node.connectedNodes.add(map[i]![j]!);
          }
        }
      }
    }

    final tileGraph = TileGraph()..allNodes = allNodes;
    final astar = AStar(tileGraph);
    final result = astar.findPathSync(allNodes[0], map[22]![15]!);
    debugPrint('path ==> $result');

    add(Monster(human, path: result)
      ..position = Vector2.zero()
      ..scale = Vector2(0.5, 0.5));
  }

  void aStar() {}
}

class TileNode extends Object with Node<TileNode> {
  Vector2 position;
  Set<TileNode> connectedNodes = <TileNode>{};
  TileNode(this.position);

  @override
  String toString() => '$position';
}

class TileGraph extends Graph<TileNode> {
  @override
  List<TileNode> allNodes = [];

  @override
  num getDistance(TileNode a, TileNode b) {
    return a.position.distanceTo(b.position);
  }

  @override
  num getHeuristicDistance(TileNode a, TileNode b) {
    return a.position.distanceTo(b.position);
  }

  @override
  Iterable<TileNode> getNeighboursOf(TileNode node) {
    return node.connectedNodes;
  }
}
