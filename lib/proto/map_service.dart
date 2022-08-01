import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/a_star.dart';
import 'package:tiled/tiled.dart';

class MapService {
  static final MapService _instance = MapService._();

  MapService._();

  factory MapService() {
    return _instance;
  }

  final double tileSize = 16;

  late List<List<MapNode?>?> _mapNodes;
  late AStar<MapNode> _aStar;

  List<Rect> getCollisionRect(TileLayer blockLayer) {
    final result = <Rect?>[];
    for (int x = 0; x < blockLayer.width; x++) {
      Vector2? from;
      Vector2 to = Vector2(tileSize, 0);
      for (int y = 0; y < blockLayer.height; y++) {
        if (from != null) to.y += tileSize;
        if (blockLayer.tileData![y][x].tile == 0) {
          if (from != null) {
            result.add(Rect.fromLTWH(from.x, from.y, to.x, to.y));
            from = null;
            to.y = 0;
          }
          continue;
        }

        from = from ?? Vector2(x * tileSize, y * tileSize);
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

  void initAStar(TileLayer blockLayer) {
    List<MapNode> allNodes = [];
    _mapNodes = []..length = blockLayer.height;
    for (int y = 0; y < blockLayer.height; y++) {
      _mapNodes[y] = []..length = blockLayer.width;
      final row = blockLayer.tileData![y];
      for (int x = 0; x < blockLayer.width; x++) {
        final grid = row[x];
        if (grid.tile != 0) continue;
        final node = MapNode(Vector2(x * 16, y * 16));
        allNodes.add(node);
        _mapNodes[y]![x] = node;
      }
    }

    for (int y = 0; y < blockLayer.height; y++) {
      for (int x = 0; x < blockLayer.width; x++) {
        final node = _mapNodes[y]![x];
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
            if (_mapNodes[i]![j] == null) continue;
            node.connectedNodes.add(_mapNodes[i]![j]!);
          }
        }
      }
    }

    final tileGraph = MapGraph()..allNodes = allNodes;
    _aStar = AStar(tileGraph);
  }

  Future<Queue<MapNode>?> getPath(Vector2 from, Vector2 to) {
    final fromIndex = from.clone()..divide(Vector2(16, 16));
    final toIndex = to.clone()..divide(Vector2(16, 16));

    if (_mapNodes[fromIndex.y.toInt()]![fromIndex.x.toInt()] == null ||
        _mapNodes[toIndex.y.toInt()]![toIndex.x.toInt()] == null) {
      return Future(() => null);
    }

    return _aStar.findPath(
      _mapNodes[fromIndex.y.toInt()]![fromIndex.x.toInt()]!,
      _mapNodes[toIndex.y.toInt()]![toIndex.x.toInt()]!,
    );
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
