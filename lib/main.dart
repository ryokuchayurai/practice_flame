import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/audio_pool.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart' hide Animation, Image;
import 'package:practice_flame/custom_fixed_resolution_viewport.dart';
import 'package:tiled/tiled.dart';

void main() {
  runApp(GameWidget(game: TiledGame()));
}

class TiledGame extends FlameGame with TapDetector, HasDraggables {
  late Image coins;
  late final JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // camera.zoom = 2;
    camera.viewport = FixedResolutionViewport(Vector2(375,667));

    final tiledMap = await TiledComponent.load('map.tmx', Vector2.all(16));
    // final tiledMap = await loadTiledComponent('map.tmx', Vector2.all(16));
    tiledMap.tileMap.setLayerVisibility(0, true);

    add(tiledMap);

    final objGroup = tiledMap.tileMap.getLayer<ObjectGroup>('AnimatedCoins');
    coins = await Flame.images.load('coins.png');

    // We are 100% sure that an object layer named `AnimatedCoins`
    // exists in the example `map.tmx`.
    for (final obj in objGroup!.objects) {
      debugPrint('${obj.x} ${obj.y}');
      add(
        SpriteAnimationComponent(
          position: Vector2(obj.x, obj.y),
          animation: SpriteAnimation.fromFrameData(
            coins,
            SpriteAnimationData.sequenced(
              amount: 8,
              stepTime: .15,
              textureSize: Vector2.all(20),
            ),
          ),
        ),
      );
    }

    pool = await AudioPool.create('fire_2.mp3', minPlayers: 3, maxPlayers: 4);
    // startBgmMusic();

    // camera.position.add(Vector2(100, 200));
    // camera.zoom = 10;

    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 100, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!joystick.delta.isZero()) {
      // final move = camera.position + (joystick.relativeDelta);
      // camera.moveTo(Vector2(move.x.roundToDouble(), move.y.roundToDouble()));
      // camera.moveTo(camera.position + (joystick.relativeDelta * 1000 * dt));
      // camera.onPositionUpdate(camera.position + (joystick.relativeDelta * 1000 * dt));
      // camera.viewport.
      // camera.position.add(joystick.relativeDelta * 100 * dt);
      camera.snapTo(camera.position + (joystick.relativeDelta * 1000 * dt));
      // camera.update(dt);
    }
  }

  late AudioPool pool;

  void startBgmMusic() {
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('music/bg_music.ogg');
  }

  void fireOne() {
    FlameAudio.audioCache.play('sfx/fire_1.mp3');
  }

  void fireTwo() {
    pool.start();
  }

  @override
  void onTapDown(TapDownInfo details) async {
    fireOne();
    // startBgmMusic();
    // if (button.containsPoint(details.eventPosition.game)) {
    //   fireTwo();
    // } else {
    //   fireOne();
    // }
    add(TextComponent(
        text: 'Hello, Flame',
        textRenderer: TextPaint(
            style: TextStyle(fontSize: 18, color: BasicPalette.white.color)))
      ..x = details.eventPosition.game.x
      ..y = details.eventPosition.game.y);

    // final sprite = await loadSprite('coins.png');
    // add(
    //   SpriteComponent(
    //     sprite: sprite,
    //     position: details.eventPosition.game,
    //     size: sprite.srcSize * 2,
    //     anchor: Anchor.center,
    //   ),
    // );

    final spriteSheet = SpriteSheet(
      image: await images.load('coins.png'),
      srcSize: Vector2(20.0, 20.0),
    );

    final spriteAnimation = spriteSheet.createAnimation(row: 0, stepTime: .15);
    final spriteComponent = SpriteAnimationComponent(
        animation: spriteAnimation,
        position: details.eventPosition.game,
        size: Vector2.all(20));

    add(spriteComponent);
  }
}
