import 'package:flame/components.dart';

class Hud extends Component with HasGameRef {
  late NineTileBoxComponent nineTileBoxComponent;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    positionType = PositionType.viewport;

    final sprite = Sprite(await gameRef.images.load('nine-tile.png'));
    final nineTileBox = NineTileBox(sprite);

    nineTileBoxComponent = NineTileBoxComponent(
      nineTileBox: nineTileBox,
      position: Vector2(50, 10),
      size: Vector2(300, 50),
      anchor: Anchor.center,
    );
    add(nineTileBoxComponent);

    add(SpriteComponent(sprite: sprite));
  }
}
