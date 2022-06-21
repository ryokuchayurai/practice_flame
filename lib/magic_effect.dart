import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:practice_flame/human1.dart';

class MagicEffect extends SpriteAnimationComponent with HasGameRef {
  MagicEffect(this.direction);

  final String _imageFile = 'magic-effect.png';
  final Vector2 _size = Vector2(8, 16);
  final Direction direction;

  final double speed = 300;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: _size);

    animation = spriteSheet.createAnimation(row: 0,
        stepTime: 0.5,
        loop: true,
        from: 0,
        to: 2);
    size = _size;

    switch(direction) {
      case Direction.up:
      case Direction.upRight:
      case Direction.upLeft:
        position.y = 9;
        position.x = 8;
        priority = -100;
        break;
      case Direction.left:
        position.y = 8;
        position.x = -4;
        break;
      case Direction.right:
        position.y = 8;
        position.x = 12;
        break;
      case Direction.down:
      case Direction.downRight:
      case Direction.downLeft:
        position.y = 10;
        position.x = 0;
        break;
    }
  }
}