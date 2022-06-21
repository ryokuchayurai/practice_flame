import 'dart:math';

import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class Magic extends SpriteAnimationComponent {
  Magic();
  static const double speed = 100;

  final Vector2 velocity = Vector2.zero();

  late ParticleSystemComponent particle;

  @override
  Future<void> onLoad() async {
    final image = await Images().load('arrow.png');
    animation = SpriteAnimation.spriteList([Sprite(image)], stepTime: 0.1);
    size = image.size;

    final Tween<double> noise = Tween(begin: -10, end: 10);
    final random = Random();
    final ColorTween colorTween = ColorTween(begin: Colors.white, end: Colors.red);

    particle = ParticleSystemComponent(
      position: Vector2(0, 0),
      particle: Particle.generate(
        count: 1,
        lifespan: 2,
        generator: (i) {
          return CircleParticle(
            radius: 2,
            paint: Paint()
              ..color = colorTween.transform(random.nextDouble())!,
          );
        },
      ),
    );

    add(particle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final deltaPosition = velocity * (speed * dt);
    position.add(deltaPosition);
  }
}