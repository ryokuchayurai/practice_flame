import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:practice_flame/a_star.dart';
import 'package:practice_flame/proto/heroine.dart';
import 'package:practice_flame/proto/main_player.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_layer.dart';
import 'package:tiled/tiled.dart';

class ProtoGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final MainPlayer _player;

  List<ProtoMonster> _monsters = [];

  late ProtoLayer _protoLayer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    collisionDetection =
        StandardCollisionDetection(broadphase: ProtoSweep<ShapeHitbox>());
    camera.viewport = FixedResolutionViewport(Vector2(400, 320));

    _loadMap();

    add(_player = MainPlayer());
    _player.position = Vector2(560, 496);
    camera.followComponent(_player,
        worldBounds: const Rect.fromLTRB(0, 0, 16.0 * 50, 16.0 * 50));

    add(Heroine()..position = Vector2(592, 496));

    // add(RectangleComponent(
    //     position: Vector2.zero(),
    //     size: Vector2(400, 320),
    //     priority: 20000,
    //     paint: Paint()..color = Colors.black.withOpacity(0.4))
    //   ..positionType = PositionType.viewport);

    // add(Hud());
    final sprite = Sprite(await images.load('nine-tile.png'));
    final nineTileBox = NineTileBox(sprite);
    add(NineTileBoxComponent(
        nineTileBox: nineTileBox,
        position: Vector2(50, 10),
        size: Vector2(300, 100),
        priority: 100000)
      ..add(TextComponent(
          text: "メニュー",
          textRenderer:
              TextPaint(style: TextStyle(color: Colors.white, fontSize: 20)))
        ..position.x += 10)
      ..positionType = PositionType.viewport);

    add(FpsTextComponent());

    // Timer(Duration(seconds: 1), () {
    //   for (int i = 0; i < 1000; i++) {
    //     _addMonster();
    //   }
    // });

    Timer.periodic(Duration(seconds: 3), (timer) {
      _addMonster();
    });

    _protoLayer = ProtoLayer(Heroine()..position = Vector2(100, 100));
  }

  void _addMonster() {
    final rnd = Random();
    if (rnd.nextBool()) {
      int x = rnd.nextBool() ? 0 : 49;
      int y = rnd.nextInt(49);
      _monsters.add(ProtoMonster(position: Vector2(x * 16.0, y * 16.0)));
      add(_monsters.last);
    } else {
      int x = rnd.nextInt(49);
      int y = rnd.nextBool() ? 0 : 49;
      _monsters.add(ProtoMonster(position: Vector2(x * 16.0, y * 16.0)));
      add(_monsters.last);
    }
  }

  ProtoMonster? getNearMonster(Vector2 pos, {double? range}) {
    final sorted = _monsters
        .where((element) =>
            range == null || element.position.distanceTo(pos).abs() < range!)
        .toList()
      ..sort((a, b) =>
          (a.position.distanceTo(pos).abs() - b.position.distanceTo(pos).abs())
              .toInt());
    if (sorted.isEmpty) return null;
    return sorted.first;
  }

  void removeMonster(ProtoMonster monster) {
    _monsters.remove(monster);
  }

  Future<void> _loadMap() async {
    final tiledMap = await TiledComponent.load('proto.tmx', Vector2.all(16));
    tiledMap.tileMap.setLayerVisibility(0, true);
    tiledMap.tileMap.setLayerVisibility(1, true);
    tiledMap.tileMap.setLayerVisibility(2, false);
    add(tiledMap);

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;

    final blockLayer = tiledMap.tileMap.getLayer<TileLayer>('block');
    PositionComponent blocks = PositionComponent();
    _getCollisionRect(blockLayer!).forEach((element) {
      blocks.add(RectangleHitbox(
          position: Vector2(element.left, element.top),
          size: Vector2(element.width, element.height))
        ..paint = hitboxPaint
        ..renderShape = true);
    });
    add(blocks);

    final tiledMapPassable =
        await TiledComponent.load('proto.tmx', Vector2.all(16));
    tiledMapPassable.tileMap.setLayerVisibility(0, false);
    tiledMapPassable.tileMap.setLayerVisibility(1, false);
    tiledMapPassable.tileMap.setLayerVisibility(2, true);
    tiledMapPassable.priority = 10000;
    add(tiledMapPassable);

    _initAStar(blockLayer!);
  }

  List<Rect> _getCollisionRect(TileLayer blockLayer) {
    final result = <Rect?>[];
    for (int x = 0; x < blockLayer.width; x++) {
      Vector2? from;
      Vector2 to = Vector2(16, 0);
      for (int y = 0; y < blockLayer.height; y++) {
        if (from != null) to.y += 16.0;
        if (blockLayer.tileData![y][x].tile == 0) {
          if (from != null) {
            result.add(Rect.fromLTWH(from.x, from.y, to.x, to.y));
            from = null;
            to.y = 0;
          }
          continue;
        }

        from = from ?? Vector2(x * 16.0, y * 16.0);
      }

      if (from != null) {
        result.add(Rect.fromLTWH(from.x, from.y, to.x, to.y));
      }
    }
    result.sort((a, b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;

      if (a.top != b.top) return (a.top - b.top).toInt();
      return (a.left - b.left).toInt();
    });

    for (int i = 1; i < result.length; i++) {
      final a = result[i - 1];
      final b = result[i];

      if (a!.top == b!.top && a!.height == b!.height && a!.right == b!.left) {
        result[i - 1] = null;
        result[i] = Rect.fromLTWH(a.left, a.top, a.width + b.width, a.height);
      }
    }

    return result.where((element) => element != null).map((e) => e!).toList();
  }

  late final List<List<MapNode?>?> mapNodes;
  late final AStar<MapNode> aStar;

  void _initAStar(TileLayer blockLayer) {
    List<MapNode> allNodes = [];
    mapNodes = []..length = blockLayer.height;
    for (int y = 0; y < blockLayer.height; y++) {
      mapNodes[y] = []..length = blockLayer.width;
      final row = blockLayer.tileData![y];
      for (int x = 0; x < blockLayer.width; x++) {
        final grid = row[x];
        if (grid.tile != 0) continue;
        final node = MapNode(Vector2(x * 16, y * 16));
        allNodes.add(node);
        mapNodes[y]![x] = node;
      }
    }

    for (int y = 0; y < blockLayer.height; y++) {
      for (int x = 0; x < blockLayer.width; x++) {
        final node = mapNodes[y]![x];
        if (node == null) {
          continue;
        }

        for (var i = y - 1; i <= y + 1; i++) {
          if (i < 0 || i >= blockLayer.height) {
            continue; // Outside Maze bounds.
          }
          for (var j = x - 1; j <= x + 1; j++) {
            if (j < 0 || j >= blockLayer.width) {
              continue; // Outside Maze bounds.
            }
            if (i == y && j == x) {
              continue; // Same tile.
            }
            if (i != y && j != x) {
              // continue; // naname nashi!
            }
            if (mapNodes[i]![j] == null) continue;
            node.connectedNodes.add(mapNodes[i]![j]!);
          }
        }
      }
    }

    final tileGraph = MapGraph()..allNodes = allNodes;
    aStar = AStar(tileGraph);
  }

  Future<Queue<MapNode>> getPath(Vector2 from, Vector2 to) {
    final fromIndex = from.clone()..divide(Vector2(16, 16));
    final toIndex = to.clone()..divide(Vector2(16, 16));

    return aStar.findPath(
      mapNodes[fromIndex.y.toInt()]![fromIndex.x.toInt()]!,
      mapNodes[toIndex.y.toInt()]![toIndex.x.toInt()]!,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _protoLayer.render(canvas);
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
