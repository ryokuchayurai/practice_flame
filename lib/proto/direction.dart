import 'package:flame/components.dart';

enum EightDirection {
  up,
  upLeft,
  upRight,
  right,
  down,
  downRight,
  downLeft,
  left,
}

extension EightDirectionExtension on EightDirection {
  static EightDirection fromVector2(Vector2 vector) {
    final d = vector.angleToSigned(Vector2(0, 1)) * radians2Degrees;
    if (d > -22.5 && d <= 22.5) {
      return EightDirection.down;
    } else if (d > -67.5 && d <= -22.5) {
      return EightDirection.downLeft;
    } else if (d > -112.5 && d <= -67.5) {
      return EightDirection.left;
    } else if (d > -157.5 && d <= -112.5) {
      return EightDirection.upLeft;
    } else if ((d > -180 && d <= -157.5) || (d > 157.5 && d <= 180)) {
      return EightDirection.up;
    } else if (d > 112.5 && d <= 157.5) {
      return EightDirection.upRight;
    } else if (d > 67.5 && d <= 112.5) {
      return EightDirection.right;
    } else {
      return EightDirection.downRight;
    }
    return EightDirection.down;
  }

  int get spriteIndex => [3, 3, 3, 1, 0, 0, 0, 2][index];
}
