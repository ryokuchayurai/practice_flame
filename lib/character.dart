import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:practice_flame/magic.dart';
import 'package:practice_flame/main.dart';

class Character extends SpriteAnimationComponent with HasGameRef {
  Character(this.sheet);

  final SpriteSheet sheet;

  late final SpriteAnimation front;
  late final SpriteAnimation back;
  late final SpriteAnimation right;
  late final SpriteAnimation left;

  late final SpriteAnimation frontMove;
  late final SpriteAnimation backMove;
  late final SpriteAnimation rightMove;
  late final SpriteAnimation leftMove;

  @override
  Future<void> onLoad() async {
    front = sheet.createAnimation(row: 0, stepTime: 0.2, loop: true, from: 0, to: 1);
    right = sheet.createAnimation(row: 1, stepTime: 0.2, loop: true, from: 0, to: 1);
    back = sheet.createAnimation(row: 2, stepTime: 0.2, loop: true, from: 0, to: 1);

    final leftSprites = await Future.wait(right.frames.map((e) async => await flipHorizontal(e.sprite)).toList());
    left = SpriteAnimation.spriteList(leftSprites, stepTime: 0.2, loop: true);

    frontMove = sheet.createAnimation(row: 0, stepTime: 0.2, loop: true, from: 1, to: 3);
    rightMove = sheet.createAnimation(row: 1, stepTime: 0.2, loop: true, from: 1, to: 3);
    backMove = sheet.createAnimation(row: 2, stepTime: 0.2, loop: true, from: 1, to: 3);

    final leftMoveSprites = await Future.wait(rightMove.frames.map((e) async => await flipHorizontal(e.sprite)).toList());
    leftMove = SpriteAnimation.spriteList(leftMoveSprites, stepTime: 0.2, loop: true);

    animation = front;
    size = Vector2(16, 32);

  }

  JoystickDirection _direction = JoystickDirection.down;

  void move(JoystickDirection direction) {
    _direction = direction;

    switch (direction) {
      case JoystickDirection.up:
      case JoystickDirection.upLeft:
      case JoystickDirection.upRight:
        animation = backMove;
        position.add(Vector2(0, -1));
        break;
      case JoystickDirection.left:
        animation = leftMove;
        position.add(Vector2(-1, 0));
        break;
      case JoystickDirection.right:
        animation = rightMove;
        position.add(Vector2(1, 0));
        break;
      case JoystickDirection.down:
      case JoystickDirection.downLeft:
      case JoystickDirection.downRight:
        animation = frontMove;
        position.add(Vector2(0, 1));
        break;
    }
  }

  void idle() {
    switch (_direction) {
      case JoystickDirection.up:
      case JoystickDirection.upLeft:
      case JoystickDirection.upRight:
        animation = back;
        break;
      case JoystickDirection.left:
        animation = left;
        break;
      case JoystickDirection.right:
        animation = right;
        break;
      case JoystickDirection.down:
      case JoystickDirection.downLeft:
      case JoystickDirection.downRight:
        animation = front;
        break;
    }
  }

  void fire(){
    final m = Magic()..position = position;
    switch (_direction) {
      case JoystickDirection.up:
      case JoystickDirection.upLeft:
      case JoystickDirection.upRight:
        m.velocity.y = -1;
        m.angle = -90 * degrees2Radians;
        break;
      case JoystickDirection.left:
        m.velocity.x = -1;
        m.angle = 180 * degrees2Radians;
        break;
      case JoystickDirection.right:
        m.velocity.x = 1;
        break;
      case JoystickDirection.down:
      case JoystickDirection.downLeft:
      case JoystickDirection.downRight:
        m.velocity.y = 1;
        m.angle = 90 * degrees2Radians;
        break;
    }
    gameRef.add(m);
  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}