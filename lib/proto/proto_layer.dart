import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:practice_flame/proto/heroine.dart';
import 'package:practice_flame/proto/info.dart';
import 'package:practice_flame/proto/main_player.dart';
import 'package:practice_flame/proto/map_service.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_game.dart';
import 'package:practice_flame/proto/proto_text_component.dart';
import 'package:practice_flame/proto/status.dart';
import 'package:tiled/tiled.dart';

abstract class ProtoLayerComponent extends Component {
  bool get isShow;

  @override
  @mustCallSuper
  void renderTree(Canvas canvas) {
    if (!isShow) return;
    super.renderTree(canvas);
  }
}

mixin ComponentRef on Component {
  T getRef<T extends Component>() {
    var c = parent;
    while (c != null) {
      if (c is T) {
        return c;
      }
      c = c.parent;
    }
    throw StateError('Cannot find reference $T in the component tree');
  }
}

class MenuLayerComponent extends ProtoLayerComponent
    with HasGameRef<ProtoGame>, KeyboardHandler {
  @override
  bool get isShow => gameStatus.mode == GameMode.levelUp;

  late final NineTileBoxComponent _menuFrame;
  late final RectangleComponent _cursorRect;

  int _cursorX = 0;
  int _cursorY = 0;

  @override
  Future<void> onLoad() async {
    priority = 100000;
    positionType = PositionType.viewport;

    final sprite = Sprite(await gameRef.images.load('nine-tile.png'));
    final nineTileBox = NineTileBox(sprite);

    add(_menuFrame = NineTileBoxComponent(
      nineTileBox: nineTileBox,
      position: Vector2(120, 200),
      size: Vector2(190, 110),
    ));

    _menu();

    _menuFrame.add(_cursorRect = RectangleComponent(
        position: Vector2(5, 8),
        size: Vector2(90, 18),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.yellow));
  }

  void _menu() {
    _menuFrame.add(ProtoTextComponent(
        () => '移動速度UP ${gameInfo.playerInfo.speed.toInt()}',
        position: Vector2(10, 10),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(ProtoTextComponent(
        () => '攻撃範囲UP ${gameInfo.playerInfo.attackRange.toInt()}',
        position: Vector2(10, 25),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(ProtoTextComponent(
        () => '攻撃力UP ${gameInfo.playerInfo.attackPower.toInt()}',
        position: Vector2(10, 40),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(ProtoTextComponent(
        () => '攻撃速度UP ${gameInfo.playerInfo.attackInterval}',
        position: Vector2(10, 55),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));

    _menuFrame.add(ProtoTextComponent(
        () => '矢の魔法UP ${gameInfo.heroineInfo.magicArrow}',
        position: Vector2(100, 10),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(TextComponent(
        text: '炎の魔法UP ${gameInfo.heroineInfo.magicCircle}',
        position: Vector2(100, 25),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(TextComponent(
        text: '氷の魔法UP ${gameInfo.heroineInfo.magicLock}',
        position: Vector2(100, 40),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(TextComponent(
        text: '雷の魔法UP ${gameInfo.heroineInfo.magicLaser}',
        position: Vector2(100, 55),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    _menuFrame.add(TextComponent(
        text: '魔法速度UP ${gameInfo.heroineInfo.castTime}',
        position: Vector2(100, 70),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isShow) return super.onKeyEvent(event, keysPressed);

    final isKeyDown = event is RawKeyDownEvent;
    if (isKeyDown) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        _cursorY--;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        _cursorY++;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        _cursorX--;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _cursorX++;
      }

      if (_cursorX < 0) {
        _cursorX = 0;
      } else if (_cursorX > 1) {
        _cursorX = 1;
      }

      if (_cursorY < 0) {
        _cursorY = 0;
      } else if (_cursorX == 0 && _cursorY > 3) {
        _cursorY = 3;
      } else if (_cursorX == 1 && _cursorY > 4) {
        _cursorY = 4;
      }

      _moveCursor();

      if (event.logicalKey == LogicalKeyboardKey.space) {
        gameStatus.mode = GameMode.main;
      }
    }

    // if (isKeyDown && event.logicalKey == LogicalKeyboardKey.space) {
    //   switch (_cursor) {
    //     case 0:
    //       gameInfo.playerInfo.speed *= 1.1;
    //       break;
    //     case 1:
    //       gameInfo.playerInfo.attackRange *= 1.1;
    //       break;
    //     case 2:
    //       gameInfo.playerInfo.knockBack *= 1.1;
    //       break;
    //     case 3:
    //       gameInfo.heroineInfo.castTime =
    //           (gameInfo.heroineInfo.castTime * 0.95).toInt();
    //       gameInfo.heroineInfo.castInterval =
    //           (gameInfo.heroineInfo.castInterval * 0.95).toInt();
    //       break;
    //     default:
    //       break;
    //   }
    //   gameStatus.mode = GameMode.main;
    // }
    return super.onKeyEvent(event, keysPressed);
  }

  void _moveCursor() {
    _cursorRect.add(MoveToEffect(
        Vector2(_cursorX * 90 + 5, _cursorY * 15 + 8),
        EffectController(
          duration: 0.1,
          infinite: false,
        )));
  }
}

class HudLayerComponent extends ProtoLayerComponent {
  @override
  bool get isShow => true;

  @override
  Future<void> onLoad() async {
    priority = 100000;
    positionType = PositionType.viewport;

    add(ProtoTextComponent(
        () =>
            'Lvl ${gameInfo.heroineInfo.level}  ${gameInfo.playerInfo.point}/${(gameInfo.heroineInfo.level * gameInfo.heroineInfo.level * 5 / 2).ceil()}p',
        position: Vector2(200, 10),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    add(ProtoTextComponent(() => 'HP ${gameInfo.playerInfo.hp}',
        position: Vector2(200, 25),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
    add(ProtoTextComponent(() => 'HP ${gameInfo.heroineInfo.hp}',
        position: Vector2(200, 40),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 10,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.white))));
  }
}

class GameOverLayerComponent extends ProtoLayerComponent
    with HasGameRef<ProtoGame>, KeyboardHandler {
  @override
  bool get isShow => gameStatus.mode == GameMode.gameOver;

  @override
  Future<void> onLoad() async {
    priority = 200001;
    positionType = PositionType.viewport;

    add(RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(400, 320),
        paint: Paint()..color = Colors.red.withOpacity(0.6)));

    add(TextComponent(text: 'GAME OVER', position: Vector2(100, 150)));
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isShow) return super.onKeyEvent(event, keysPressed);

    final isKeyDown = event is RawKeyDownEvent;
    if (isKeyDown && event.logicalKey == LogicalKeyboardKey.keyC) {
      gameRef.reset();
      return false;
    }

    return super.onKeyEvent(event, keysPressed);
  }
}

class MainLayerComponent extends ProtoLayerComponent {
  @override
  bool get isShow => true;

  final MainPlayer player = MainPlayer();
  final Heroine heroine = Heroine();

  List<Enemy> _monsters = [];

  @override
  Future<void> onLoad() async {
    _loadMap();

    gameInfo.reset();

    add(player);
    player.position = Vector2(560, 496);

    add(heroine);
    heroine.position = Vector2(592, 496);

    Timer.periodic(const Duration(seconds: 3), (timer) {
      for (int i = 0; i < (gameInfo.heroineInfo.level / 3).ceil(); i++) {
        _addMonster();
      }
    });
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
    MapService().getCollisionRect(blockLayer!).forEach((element) {
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

    MapService().initAStar(blockLayer);
  }

  void _addMonster() {
    final rnd = Random();
    if (rnd.nextBool()) {
      int x = rnd.nextBool() ? 0 : 49;
      int y = rnd.nextInt(49);
      _monsters.add(
          BigMonster(target: heroine, position: Vector2(x * 16.0, y * 16.0)));
      add(_monsters.last);
    } else {
      int x = rnd.nextInt(49);
      int y = rnd.nextBool() ? 0 : 49;
      _monsters.add(
          SmallMonster(target: heroine, position: Vector2(x * 16.0, y * 16.0)));
      add(_monsters.last);
    }
  }

  Enemy? getNearEnemy(Vector2 pos, {double? range}) {
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

  void removeMonster(Enemy enemy) {
    _monsters.remove(enemy);
  }
}
