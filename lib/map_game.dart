import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:practice_flame/human1.dart';
import 'package:tiled/tiled.dart';

class MapGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection  {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final v1 = Vector2(100, 100);
    final v2 = Vector2(200, 100);
    debugPrint('angleToSigned: ${v1.angleTo(v2) * radians2Degrees}');

    camera.viewport = FixedResolutionViewport(Vector2(400, 300));

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
        PositionComponent(
          position: Vector2(obj.x, obj.y),
          children: [
            RectangleHitbox(
              // position: Vector2(obj.x, obj.y),
              size: Vector2(obj.width, obj.height),
            )..paint = hitboxPaint
              ..renderShape = true,
          ]
        ),
      );
    }

    final tiledMapPassable = await TiledComponent.load('danchi.tmx', Vector2.all(16));
    tiledMapPassable.tileMap.setLayerVisibility(0, false);
    tiledMapPassable.tileMap.setLayerVisibility(1, false);
    tiledMapPassable.tileMap.setLayerVisibility(2, true);
    tiledMapPassable.priority = 100;
    add(tiledMapPassable);

    final human = Human();
    add(human);

    camera.followComponent(human, worldBounds: Rect.fromLTRB(0, 0, 100 * 16, 100 * 16));

    add(RectangleComponent(position:Vector2.zero(), size:Vector2(400,300),
        priority: 10000,
        paint:Paint()..color=Colors.red.withOpacity(0.3)  ));

    add(CircleComponent(position: Vector2(100,100),radius: 100,
        priority: 10001,
        paint: Paint()..color=Colors.white.withOpacity(0.1)
        ..blendMode=BlendMode.lighten
    ));
    
    add(FpsTextComponent());
  }

}