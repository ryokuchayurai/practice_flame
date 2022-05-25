import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/audio_pool.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Animation, Image;
import 'package:google_fonts/google_fonts.dart';
import 'package:tiled/tiled.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.brown,
          scaffoldBackgroundColor: Color.fromARGB(0xFF, 0xFE, 0xFE, 0xF9),
          textTheme: GoogleFonts.sawarabiMinchoTextTheme()),
      home: MyAppHome()));
}

class MyAppHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: TiledGame(),
    );
  }
}

enum Screen {
  Test1,
  Test2,
}

class MyGame extends FlameGame with TapDetector, HasDraggables, KeyboardEvents {
  List<FlameGame> _stack = [];

  @override
  Future<void> onLoad() async {
    await push(Screen.Test1);
  }

  Future<void> push(Screen screen) async {
    switch (screen) {
      case Screen.Test1:
        _stack.add(TiledGame());
        break;
      case Screen.Test2:
        _stack.add(TestGame());
        break;
    }
    await add(_stack.last);
  }

  Future<void> pop() async {
    remove(_stack.last);
    _stack.removeLast();
  }

  Future<void> popAndPush(Screen screen) async {
    pop();
    push(screen);
  }

  @override
  void onTapDown(TapDownInfo details) async {
    super.onTapDown(details);
    if (_stack.last is TiledGame) {
      (_stack.last as TiledGame).onTapDown(details);
    }
  }
}

class TiledGame extends FlameGame
    with TapDetector, HasDraggables, KeyboardEvents {
  late Image coins;
  late final JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // camera.zoom = 2;
    camera.viewport = FixedResolutionViewport(Vector2(375, 667));

    final tiledMap = await TiledComponent.load('map.tmx', Vector2.all(16));
    // final tiledMap = await loadTiledComponent('map.tmx', Vector2.all(16));
    tiledMap.tileMap.setLayerVisibility(0, true);

    add(tiledMap);

    final objGroup = tiledMap.tileMap.getLayer<ObjectGroup>('AnimatedCoins');
    var coins = await Flame.images.load('coins.png');

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
            style: TextStyle(
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white)))
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

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is RawKeyDownEvent;

    if (event.logicalKey == LogicalKeyboardKey.keyX) {
      Navigator.of(buildContext!).pop();
      Navigator.of(buildContext!).push(MaterialPageRoute(builder: (context) {
        return GameWidget(game: TestGame());
      }));
    }

    return super.onKeyEvent(event, keysPressed);
  }
}

class TestGame extends FlameGame with TapDetector {
  final random = Random();
  final Tween<double> noise = Tween(begin: -10, end: 10);
  final ColorTween colorTween =
      ColorTween(begin: Colors.white, end: Colors.red);
  late final coins;

  @override
  Future<void> onLoad() async {
    coins = await Flame.images.load('coins.png');
    add(TextComponent(
        text: 'ああああああ',
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));

    add(
      ParticleSystemComponent(
        position: Vector2(100, 100),
        particle: Particle.generate(
          count: 40,
          lifespan: 5,
          generator: (i) {
            return AcceleratedParticle(
              speed: Vector2(
                    noise.transform(random.nextDouble()),
                    noise.transform(random.nextDouble()),
                  ) *
                  i.toDouble(),
              child: CircleParticle(
                radius: 2,
                paint: Paint()
                  ..color = colorTween.transform(random.nextDouble())!,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void onTapDown(TapDownInfo info) async {
    add(ParticleSystemComponent(
        position: info.eventPosition.game, particle: animationParticle()));
  }

  Particle fireworkParticle() {
    // A pallete to paint over the "sky"
    final paints = [
      Colors.amber,
      Colors.amberAccent,
      Colors.red,
      Colors.redAccent,
      Colors.yellow,
      Colors.yellowAccent,
      // Adds a nice "lense" tint
      // to overall effect
      Colors.blue,
    ].map((color) => Paint()..color = color).toList();

    return Particle.generate(
      count: 100,
      lifespan: 1,
      generator: (i) {
        final initialSpeed = randomCellVector2();
        final deceleration = initialSpeed * -1;
        final gravity = Vector2(0, 1000);

        return AcceleratedParticle(
          speed: initialSpeed,
          acceleration: gravity,
          // acceleration: deceleration,// + gravity,

          child: ComputedParticle(
            renderer: (canvas, particle) {
              final paint = randomElement(paints);
              // Override the color to dynamically update opacity
              // paint.color = paint.color.withOpacity(1 - particle.progress);

              canvas.drawCircle(
                Offset.zero,
                // Closer to the end of lifespan particles
                // will turn into larger glaring circles
                random.nextDouble() * particle.progress > .6
                    ? random.nextDouble() * (50 * particle.progress)
                    : 5 + (3 * particle.progress),
                paint,
              );
            },
          ),
        );
      },
    );
  }

  Vector2 randomCellVector2() {
    return (Vector2.random() - Vector2.random())..multiply(Vector2(1000, 1000));
  }

  T randomElement<T>(List<T> list) {
    return list[random.nextInt(list.length)];
  }

  Particle animationParticle() {
    return Particle.generate(
        count: 100,
        lifespan: 1,
        generator: (i) {
          final initialSpeed = randomCellVector2();
          final deceleration = initialSpeed * -1;
          final gravity = Vector2(0, 1000);

          return AcceleratedParticle(
              speed: initialSpeed,
              acceleration: gravity,
              // acceleration: deceleration,// + gravity,

              child: SpriteAnimationParticle(
                animation: getBoomAnimation(),
                size: Vector2(20, 20),
              ));
        });
  }

  SpriteAnimation getBoomAnimation() {
    const columns = 8;
    const rows = 1;
    const frames = columns * rows;
    final spritesheet = SpriteSheet.fromColumnsAndRows(
      image: coins,
      columns: columns,
      rows: rows,
    );
    final sprites = List<Sprite>.generate(frames, spritesheet.getSpriteById);
    return SpriteAnimation.spriteList(sprites, stepTime: 0.2);
  }
}
