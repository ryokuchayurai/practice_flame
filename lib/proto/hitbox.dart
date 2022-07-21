import 'package:flame/collisions.dart';

class ProtoHitbox extends RectangleHitbox {
  ProtoHitbox(
    this.tag, {
    super.position,
    super.size,
    super.angle,
    super.anchor,
    super.priority,
    this.ignore,
  });

  final String tag;
  final List<String>? ignore;

  bool isTarget(Hitbox other) {
    if (other is ProtoHitbox) {
      if (tag == other.tag) return false;
      if (ignore == null) return true;
      return !(ignore!.contains(other.tag));
    }
    return true;
  }
}
