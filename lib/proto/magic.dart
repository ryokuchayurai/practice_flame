import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/proto/hitbox.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_game.dart';

mixin AttackDamage {
  late int damagePoint;
  late Color damageColor;

  late Vector2 force;
  //
  // Vector2 get forceSource;
  // late double forcePower;
  //
  // Vector2 getForce(Vector2 target) {
  //   final a = atan2(target.y - forceSource.y, target.x - forceSource.x);
  //   return Vector2(cos(a) * forcePower, sin(a) * forcePower);
  // }

  void preProcess(Enemy enemy) {}
  void afterProcess(Enemy enemy) {}
}

class ArrowMagic extends SpriteAnimationComponent
    with HasGameRef, AttackDamage {
  ArrowMagic({super.position, required this.target}) {
    damagePoint = 30;
    damageColor = Colors.white;
  }

  final Vector2 target;
  late Vector2 targetFar;
  final double speed = 200;

  int hp = 30;

  @override
  Future<void> onLoad() async {
    size = Vector2(10, 5);

    angle = atan2(target.y - position.y, target.x - position.x);
    // double deg = angle * radians2Degrees + (Random().nextDouble() * 60 - 30);
    // angle = deg * degrees2Radians;

    force = Vector2(cos(angle) * 70, sin(angle) * 70);
    targetFar = Vector2(cos(angle) * 200, sin(angle) * 200)..add(position);

    debugPrint('magic -> $targetFar');
    (gameRef as ProtoGame).showPoint(targetFar);

    final image = await gameRef.images.load('magic-arrow.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1);

    add(RectangleHitbox(
      position: Vector2(0, 0),
      size: size,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.moveToTarget(targetFar, speed * dt);
    if (targetFar.distanceTo(position).abs() < 1) {
      removeFromParent();
    }
  }

  @override
  void preProcess(Enemy enemy) {
    hp -= damagePoint;
    if (hp <= 0) {
      removeFromParent();
    }
  }
}

class FireMagic extends SpriteAnimationComponent with HasGameRef, AttackDamage {
  FireMagic({this.onComplete}) {
    damagePoint = 30;
    damageColor = Colors.red;
    force = Vector2.zero();
  }

  final void Function(FireMagic)? onComplete;

  @override
  Future<void> onLoad() async {
    size = Vector2(13, 16);

    final image = await gameRef.images.load('magic-fire.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: size);
    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1);

    add(ProtoHitbox('fire',
        position: Vector2(0, 0), size: size, ignore: ['leg', 'body']));

    final path2 = Path()..addOval(const Rect.fromLTRB(-50, -50, 50, 50));
    add(MoveAlongPathEffect(
        path2,
        EffectController(
          duration: 5,
          // startDelay: i * 0.3,
          // infinite: true,
        ),
        oriented: false, onComplete: () {
      onComplete?.call(this);
      removeFromParent();
    }));
  }
}

class IceMagic extends SpriteAnimationComponent with HasGameRef, AttackDamage {
  IceMagic(this.target) {
    damagePoint = 10;
    damageColor = Colors.blue;
    force = Vector2.zero();
  }

  final Enemy target;

  double _slowFactor = 0.6;
  int _slowDuration = 3;

  @override
  Future<void> onLoad() async {
    size = Vector2(32, 32);
    anchor = Anchor.center;
    priority = 10000;
    setOpacity(0.6);

    final image = await gameRef.images.load('magic-ice.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: size);
    animation = spriteSheet.createAnimationWithVariableStepTimes(
        row: 0, stepTimes: [0.1, 0.1, 0.1, 0.5], loop: false);
    removeOnFinish = true;

    // add(ProtoHitbox('ice',
    //     position: Vector2(0, 0), size: size, ignore: ['leg', 'body']));

    position = target.position;

    target.damage(this);
    target.slowDown(_slowFactor, duration: Duration(seconds: _slowDuration));
  }
}

class ThunderMagic extends PositionComponent
    with HasGameRef, HasPaint, AttackDamage {
  ThunderMagic(this.from) {
    damagePoint = 30;
    damageColor = Colors.yellow;
  }

  final Vector2 from;
  late final Vector2 to;
  late final Vector2 target;

  final _sprites = <SpriteAnimationComponent>[];
  late final ProtoHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    to = from.clone();
    priority = 10000;

    double r = Random().nextInt(360) * degrees2Radians;
    target = Vector2(300 * cos(r), 300 * sin(r));
    target.add(from);
    //
    // target = from.clone();
    // target.x -= 300;
    // target.y += 40;

    force = Vector2(cos(r) * 90, sin(r) * 90);

    paint.color = Colors.white;
    paint.strokeWidth = 5;
    paint.strokeCap = StrokeCap.round;

    final image = await gameRef.images.load('magic-thunder.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(13, 16));

    for (int i = 0; i < 1; i++) {
      final animation =
          spriteSheet.createAnimation(row: 0, stepTime: 0.1 * i + 0.1);
      _sprites.add(SpriteAnimationComponent(
          paint: paint,
          anchor: Anchor.center,
          animation: animation,
          position: to.clone(),
          size: Vector2(26, 32)));
      // _sprites.last.tint(Colors.white);
      add(_sprites.last);
    }

    _hitbox = ProtoHitbox('thunder',
        position: _sprites.last.position, size: _sprites.last.size);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    to.moveToTarget(target, 500 * dt);
    for (final s in _sprites) {
      s.position.moveToTarget(target, 500 * dt);
    }
    _hitbox.position = _sprites.first.position;

    if (to.distanceTo(target).abs() < 1) {
      add(OpacityEffect.fadeOut(
          EffectController(
            duration: 0.3,
          ),
          onComplete: () => removeFromParent()));
    }

    paint.color = Random().nextBool() ? Colors.white : Colors.yellow;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(from.toOffset(), to.toOffset(), paint);
  }
}
