import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Magic extends SpriteAnimationComponent {
  Magic();
  static const double speed = 100;

  final Vector2 velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final image = await Images().load('arrow.png');
    animation = SpriteAnimation.spriteList([Sprite(image)], stepTime: 0.1);
    size = image.size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final deltaPosition = velocity * (speed * dt);
    position.add(deltaPosition);


  }
}