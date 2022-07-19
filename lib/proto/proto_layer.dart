import 'package:flame/components.dart';
import 'package:flame/layers.dart';

class ProtoLayer extends DynamicLayer {
  ProtoLayer(this.component);
  Component? component;

  @override
  void drawLayer() {
    component?.renderTree(canvas);
  }
}
