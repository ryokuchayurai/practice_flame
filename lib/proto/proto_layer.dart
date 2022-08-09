import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:practice_flame/proto/bubble.dart';
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

class Skill {
  Skill(this.name, this.icon, this.descriptions);
  String name;
  String icon;
  List<String> descriptions;

  late Sprite iconSprite;
}

class MenuLayerComponent extends ProtoLayerComponent
    with HasGameRef<ProtoGame>, KeyboardHandler {
  @override
  bool get isShow => gameStatus.mode == GameMode.levelUp;
  // bool get isShow => true;

  late final NineTileBoxComponent _selectedFrame;
  late final NineTileBoxComponent _menuFrame;
  late final RectangleComponent _cursorRect;

  int _cursorX = 0;
  int _cursorY = 0;

  final _skills = <Skill>[
    Skill('走力の魔法', 'skill-icon.png', [
      '足に加速の魔法をかけて早く走れるようにする。',
      'もっと早く走れるようにする。',
      'もっともっと早く走れるようにする。',
      'もっともっともっと早く走れるようにする。',
      'もっともっともっともっと早く走れるようにする。',
    ]),
    Skill('剛腕の魔法', 'skill-icon.png', [
      '腕力を強化する魔法をかけてバットで殴った時の威力を上げる。',
      'もっとバットの威力を上げる。',
      'もっともっとバットの威力を上げる。',
      'もっともっともっとバットの威力を上げる。',
      'もっともっともっともっとバットの威力を上げる。',
    ]),
    Skill('拡大の魔法', 'skill-icon.png', [
      'バットの認識を拡大し遠くまで届くようにする。',
      'バットをもっと遠くまで届くようにする。',
      'バットをもっともっと遠くまで届くようにする。',
      'バットをもっともっともっと遠くまで届くようにする。',
      'バットをもっともっともっともっと遠くまで届くようにする。',
    ]),
    Skill('軽量の魔法', 'skill-icon.png', [
      'バットを軽くして早く振れるようにする。',
      'バットをもっと早く振れるようにする。',
      'バットをもっともっと早く振れるようにする。',
      'バットをもっともっともっと早く振れるようにする。',
      'バットをもっともっともっともっと早く振れるようにする。',
    ]),
    Skill('矢の魔法', 'skill-icon.png', [
      '一番近くの敵に魔法の矢を飛ばす。',
      '矢の魔法をもっと強化する。',
      '矢の魔法をもっともっと強化する。',
      '矢の魔法をもっともっともっと強化する。',
      '矢の魔法をもっともっともっともっと強化する。',
    ]),
    Skill('氷の魔法', 'skill-icon.png', [
      '敵を氷漬けにしてダメージを与え、すこしのあいだ移動速度を遅くする。',
      '氷の魔法をもっと強化する。',
      '氷の魔法をもっともっと強化する。',
      '氷の魔法をもっともっともっと強化する。',
      '氷の魔法をもっともっともっともっと強化する。',
    ]),
    Skill('炎の魔法', 'skill-icon.png', [
      'まわりを旋回する炎をつくる。',
      '炎の魔法をもっと強化する。',
      '炎の魔法をもっともっと強化する。',
      '炎の魔法をもっともっともっと強化する。',
      '炎の魔法をもっともっともっともっと強化する。',
    ]),
    Skill('雷の魔法', 'skill-icon.png', [
      '強力な雷を飛ばす。どこに飛ぶかはわからない。',
      '雷の魔法をもっと強化する。',
      '雷の魔法をもっともっと強化する。',
      '雷の魔法をもっともっともっと強化する。',
      '雷の魔法をもっともっともっともっと強化する。',
    ]),
  ];

  @override
  Future<void> onLoad() async {
    priority = 100000;
    positionType = PositionType.viewport;

    final sprite = Sprite(await gameRef.images.load('nine-tile.png'));
    final nineTileBox = NineTileBox(sprite);

    add(_selectedFrame = NineTileBoxComponent(
      nineTileBox: nineTileBox,
      position: Vector2(165, 70),
      size: Vector2(100, 160),
    ));

    add(_menuFrame = NineTileBoxComponent(
      nineTileBox: nineTileBox,
      position: Vector2(120, 210),
      size: Vector2(190, 80),
    ));

    _menuFrame.add(_cursorRect = RectangleComponent(
        position: Vector2(5, 8),
        size: Vector2(90, 18),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.yellow));

    for (final skill in _skills) {
      skill.iconSprite = Sprite(await gameRef.images.load(skill.icon));
    }

    _menu();
    _selected();
  }

  void _menu() {
    final pos = Vector2(10, 10);
    for (final skill in _skills) {
      final i = _skills.indexOf(skill);
      final max = gameInfo.skillInfo.skills[i] >= 4;

      _menuFrame.add(ProtoTextComponent(() => skill.name,
          position: pos,
          textRenderer: TextPaint(
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                  color: max ? Colors.grey : Colors.white))));

      pos.add(Vector2(0, 15));
      if (pos.y > 55) {
        pos.y = 10;
        pos.x = 100;
      }
    }
  }

  void _selected() {
    final i = _cursorY + _cursorX * 4;
    final skill = _skills[i];
    for (var element in _selectedFrame.children) {
      element.removeFromParent();
    }

    _selectedFrame.add(
        SpriteComponent(sprite: skill.iconSprite, position: Vector2(34, 10)));
    _selectedFrame.add(ProtoTextBoxComponent(
        text: skill.descriptions[gameInfo.skillInfo.skills[i]],
        position: Vector2(0, 44),
        boxConfig: TextBoxConfig(maxWidth: 100, growingBox: true),
        lineBreakInWord: true,
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
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _cursorY--;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _cursorY++;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _cursorX--;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
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
      } else if (_cursorX == 1 && _cursorY > 3) {
        _cursorY = 3;
      }

      _moveCursor();
      _selected();
    }

    if (event.logicalKey == LogicalKeyboardKey.space &&
        event is RawKeyUpEvent) {
      final i = _cursorY + _cursorX * 4;
      gameInfo.skillInfo.skills[i] += 1;
      if (gameInfo.skillInfo.skills[i] > 4) gameInfo.skillInfo.skills[i] = 4;
      gameStatus.mode = GameMode.main;
    }

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

    add(CircleComponent(
        position: Vector2.zero(),
        radius: 100,
        paint: Paint()..color = Colors.white.withOpacity(0.8)));

    add(RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(400, 320),
        paint: Paint()..color = Colors.red.withOpacity(0.8)));

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

    _addSmallMonster();
    _addBigMonster();
    _addChargeMonster();
  }

  void _addSmallMonster() {
    final rnd = Random();
    Timer.periodic(Duration(seconds: 5), (timer) {
      int s = _elapsed ~/ 60 + 1;

      for (int i = 0; i < s; i++) {
        if (rnd.nextBool()) {
          int x = rnd.nextBool() ? 0 : 49;
          int y = rnd.nextInt(49);
          _monsters.add(SmallMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        } else {
          int x = rnd.nextInt(49);
          int y = rnd.nextBool() ? 0 : 49;
          _monsters.add(SmallMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        }
      }
    });
  }

  void _addBigMonster() {
    final rnd = Random();
    Timer.periodic(Duration(seconds: 20), (timer) {
      int m = _elapsed ~/ 60;

      for (int i = 0; i < m; i++) {
        if (rnd.nextBool()) {
          int x = rnd.nextBool() ? 0 : 49;
          int y = rnd.nextInt(49);
          _monsters.add(BigMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        } else {
          int x = rnd.nextInt(49);
          int y = rnd.nextBool() ? 0 : 49;
          _monsters.add(BigMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        }
      }
    });
  }

  void _addChargeMonster() {
    final rnd = Random();
    Timer.periodic(Duration(seconds: 60), (timer) {
      int l = _elapsed ~/ 60;

      for (int i = 0; i < l; i++) {
        if (rnd.nextBool()) {
          int x = rnd.nextBool() ? 0 : 49;
          int y = rnd.nextInt(49);
          _monsters.add(ChargeMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        } else {
          int x = rnd.nextInt(49);
          int y = rnd.nextBool() ? 0 : 49;
          _monsters.add(ChargeMonster(
              target: heroine, position: Vector2(x * 16.0, y * 16.0)));
          add(_monsters.last);
        }
      }
    });
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

  double _elapsed = 0;
  @override
  void update(double dt) {
    _elapsed += dt;
  }
}

class CutsceneLayerComponent extends ProtoLayerComponent
    with HasGameRef<ProtoGame>, KeyboardHandler {
  @override
  bool get isShow => true;

  final MainPlayer player = MainPlayer();
  final Heroine heroine = Heroine();

  @override
  Future<void> onLoad() async {
    _loadScene();

    add(player);
    player.scale = Vector2.all(2);
    add(heroine);
  }

  void _loadScene() {}

  void _play() {}
}
