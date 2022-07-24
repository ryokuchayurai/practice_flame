import 'dart:collection';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/proto/gem.dart';
import 'package:practice_flame/proto/hitbox.dart';
import 'package:practice_flame/proto/magic.dart';
import 'package:practice_flame/proto/proto_game.dart';
import 'package:practice_flame/proto/proto_layer.dart';
import 'package:practice_flame/proto/weapon.dart';

class ProtoMonster extends SpriteAnimationComponent
    with HasGameRef<ProtoGame>, CollisionCallbacks, ComponentRef {
  ProtoMonster({super.position});

  final double speed = 20;

  Queue<MapNode>? _path;

  int hp = 3;

  @override
  Future<void> onLoad() async {
    size = Vector2(16, 16);
    anchor = Anchor.center;

    final shadow = await gameRef.images.load('shadow.png');
    add(SpriteComponent.fromImage(shadow,
        paint: Paint()..color = Colors.black.withOpacity(0.2),
        position: Vector2(2, 28),
        size: shadow.size,
        priority: -1));

    // final image = await gameRef.images.load('monster1.png');
    final image = await gameRef.images.load('he.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));

    animation = spriteSheet.createAnimation(
        row: 0, stepTime: 0.2, loop: true, from: 0, to: 5);

    // tint(Colors.blue);

    // setOpacity(0.8);

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;
    add(
      ProtoHitbox(
        'monster',
        position: Vector2(0, 0),
        size: size,
        ignore: ['gem'],
      )
        ..paint = hitboxPaint
        ..renderShape = false,
    );

    getRef<MainLayerComponent>()
        .getPath(position, Vector2(592, 496))
        .then((value) => _path = value);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_path != null) {
      if (_path?.isNotEmpty ?? false) {
        final target = _path!.first.position;
        position.moveToTarget(target, speed * dt);
        if (position.distanceTo(target) < 1) {
          _path!.removeFirst();
        }
        priority = position.y.toInt();
      }
      return;
    }
    // final r =
    //     atan2(human.position.y - position.y, human.position.x - position.x);
    // final deltaPosition = Vector2(cos(r) * (speed * dt), sin(r) * (speed * dt));
    // position.add(deltaPosition);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is ProtoMagic) {
      _damageEffect(other.force, onComplete: () {
        getRef<MainLayerComponent>().removeMonster(this);
        removeFromParent();
        getRef<MainLayerComponent>().add(ProtoGem()..position = this.position);
      });
    }
    if (other is ProtoWeapon) {
      _damageEffect(other.force, onComplete: () {
        hp--;
        if (hp < 0) {
          getRef<MainLayerComponent>().removeMonster(this);
          removeFromParent();
          getRef<MainLayerComponent>()
              .add(ProtoGem()..position = this.position);
        }
      });
    }
  }

  void _damageEffect(Vector2 force, {Function()? onComplete}) {
    add(ColorEffect(Colors.white, const Offset(0, 1),
        EffectController(duration: 0.1, reverseDuration: 0.1, repeatCount: 3)));
    add(
      MoveEffect.by(
          force,
          EffectController(
            duration: 0.25,
            infinite: false,
          ),
          onComplete: onComplete),
    );
  }
}

// class ProtoMonsterHitbox extends RectangleHitbox {
//   ProtoMonsterHitbox({
//     super.position,
//     super.size,
//     super.angle,
//     super.anchor,
//     super.priority,
//   });
// }

class ProtoSweep<T extends Hitbox<T>> extends Broadphase<T> {
  ProtoSweep({super.items});

  final List<T> _active = [];
  final Set<CollisionProspect<T>> _potentials = {};

  @override
  Set<CollisionProspect<T>> query() {
    _active.clear();
    _potentials.clear();
    items.sort((a, b) => (a.aabb.min.x - b.aabb.min.x).ceil());
    for (final item in items) {
      if (item.collisionType == CollisionType.inactive) {
        continue;
      }
      if (_active.isEmpty) {
        _active.add(item);
        continue;
      }
      final currentBox = item.aabb;
      final currentMin = currentBox.min.x;
      for (var i = _active.length - 1; i >= 0; i--) {
        if (_filter(item, _active[i])) continue;

        final activeItem = _active[i];
        final activeBox = activeItem.aabb;
        if (activeBox.max.x >= currentMin) {
          if (item.collisionType == CollisionType.active ||
              activeItem.collisionType == CollisionType.active) {
            _potentials.add(CollisionProspect<T>(item, activeItem));
          }
        } else {
          _active.remove(activeItem);
        }
      }
      _active.add(item);
    }
    return _potentials;
  }

  bool _filter(T a, T b) {
    if (a is ProtoHitbox) {
      return !((a as ProtoHitbox).isTarget(b));
    }
    return false;
  }
}
