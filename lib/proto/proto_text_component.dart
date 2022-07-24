import 'package:flame/components.dart';

typedef TextBuilder = String Function();

class ProtoTextComponent extends TextComponent {
  ProtoTextComponent(
    this.textBuilder, {
    super.textRenderer,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    this.updateInterval = 0.5,
  }) {
    super.text = textBuilder();
  }

  final TextBuilder textBuilder;
  final double updateInterval;

  double _counter = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _counter += dt;
    if (_counter > updateInterval) {
      text = textBuilder();
      _counter = 0;
    }
  }
}
