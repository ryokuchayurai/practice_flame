import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:practice_flame/human1.dart';

class Bat extends SpriteComponent with HasGameRef {
  Bat(this.direction, {this.onComplete});

  final Direction direction;
  final void Function(Bat)? onComplete;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('bat.png');
    sprite = Sprite(image);
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    position = Vector2(3, 18);
    anchor = Anchor.centerRight;

    double fromDeg = 0;
    double toDeg = 0;
    switch (direction) {
      case Direction.up:
      case Direction.upLeft:
      case Direction.upRight:
        fromDeg = 0;
        toDeg = 180;
        break;
      case Direction.left:
        fromDeg = 90;
        toDeg = -90;
        break;
      case Direction.right:
        fromDeg = -90;
        toDeg = 90;
        break;
      case Direction.down:
      case Direction.downLeft:
      case Direction.downRight:
        fromDeg = 180;
        toDeg = 0;
        break;
    }

    angle = degrees2Radians * fromDeg;

    add(
      RotateEffect.to(
        degrees2Radians * toDeg,
        onComplete: () => onComplete?.call(this),
        EffectController(
          duration: 0.2,
          infinite: false,
        ),
      ),
    );
  }
}
