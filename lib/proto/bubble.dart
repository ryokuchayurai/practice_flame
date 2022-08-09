import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:google_fonts/google_fonts.dart';
import 'package:practice_flame/proto/proto_game.dart';
import 'package:practice_flame/proto/sound_service.dart';

class Bubble extends PositionComponent with HasGameRef<ProtoGame> {
  Bubble(this.text,
      {this.timePerChar = 0.05,
      this.sound,
      this.maxWidth = 100,
      this.closeDuration,
      this.onFinish});

  final String text;
  final double timePerChar;
  final String? sound;
  final double maxWidth;
  final Duration? closeDuration;
  final VoidCallback? onFinish;

  late ProtoTextBoxComponent _textBox;

  late NineTileBoxComponent _bubble;

  @override
  Future<void> onLoad() async {
    final sprite = Sprite(await gameRef.images.load('bubble.png'));
    final point = Sprite(await gameRef.images.load('bubble-point.png'));

    final nineTileBox = NineTileBox(sprite);

    add(_bubble = NineTileBoxComponent(
        nineTileBox: nineTileBox,
        size: Vector2(0, 0),
        position: Vector2(0, point.srcSize.y * -1 + 1)));
    _bubble.anchor = Anchor.bottomCenter;

    add(SpriteComponent(sprite: point)..anchor = Anchor.bottomCenter);

    add(_textBox = ProtoTextBoxComponent(
        text: text,
        position: Vector2(0, point.srcSize.y * -1 + 1),
        textRenderer: TextPaint(
            style: TextStyle(
                fontSize: 8,
                fontFamily: GoogleFonts.sawarabiMincho().fontFamily,
                color: Colors.black)),
        boxConfig: TextBoxConfig(
          maxWidth: maxWidth,
          timePerChar: timePerChar,
          growingBox: true,
          margins: EdgeInsets.all(8),
        ),
        lineBreakInWord: true,
        onDrawChara: _playSound,
        onFinish: () {
          if (closeDuration != null) {
            Timer(closeDuration!, () => removeFromParent());
          }
          onFinish?.call();
        }));
    _textBox.anchor = Anchor.bottomCenter;
  }

  @override
  void update(double dt) {
    _bubble.size = _textBox.size;
    if (_bubble.size.x < 48) {
      _bubble.size.x = 48;
    }
  }

  final _silent = [' ', '　', '.', '。', '、'];

  void _playSound(String c) {
    if (!_silent.contains(c) && sound != null) {
      SoundService().play(sound!);
    }
  }
}

class ProtoTextBoxComponent<T extends TextRenderer> extends TextComponent {
  static final Paint _imagePaint = BasicPalette.white.paint();
  // ..isAntiAlias = false
  // ..filterQuality = FilterQuality.high;
  final TextBoxConfig _boxConfig;
  final double pixelRatio;

  final List<String> _lines = [];
  double _maxLineWidth = 0.0;
  late double _lineHeight;
  late int _totalLines;

  double _lifeTime = 0.0;
  int? _previousChar;

  @visibleForTesting
  Image? cache;

  TextBoxConfig get boxConfig => _boxConfig;

  final bool lineBreakInWord;

  final void Function(String)? onDrawChara;

  bool isCalledFinish = false;
  final VoidCallback? onFinish;

  ProtoTextBoxComponent(
      {super.text,
      T? super.textRenderer,
      TextBoxConfig? boxConfig,
      Anchor? align,
      double? pixelRatio,
      super.position,
      super.size,
      super.scale,
      super.angle,
      super.anchor,
      super.children,
      super.priority,
      this.lineBreakInWord = false,
      this.onDrawChara,
      this.onFinish})
      : _boxConfig = boxConfig ?? TextBoxConfig(),
        _fixedSize = size != null,
        align = align ?? Anchor.topLeft,
        pixelRatio = pixelRatio ?? window.devicePixelRatio;

  /// Alignment of the text within its bounding box.
  ///
  /// This property combines both the horizontal and vertical alignment. For
  /// example, setting this property to `Align.center` will make the text
  /// centered inside its box. Similarly, `Align.bottomRight` will render the
  /// text that's aligned to the right and to the bottom of the box.
  ///
  /// Custom alignment anchors are supported too. For example, if this property
  /// is set to `Anchor(0.1, 0)`, then the text would be positioned such that
  /// its every line will have 10% of whitespace on the left, and 90% on the
  /// right. You can use an `AnchorEffect` to make the text gradually transition
  /// between different alignment values.
  Anchor align;

  /// If true, the size of the component will remain fixed. If false, the size
  /// will expand or shrink to the fit the text.
  ///
  /// This property is set to true if the user has explicitly specified [size]
  /// in the constructor.
  final bool _fixedSize;

  @override
  set text(String value) {
    if (text != value) {
      super.text = value;
      // This ensures that the component will redraw on next update
      _previousChar = -1;
    }
  }

  @override
  @mustCallSuper
  Future<void> onLoad() {
    return redraw();
  }

  @override
  @mustCallSuper
  void onMount() {
    if (cache == null) {
      redraw();
    }
  }

  @override
  void updateBounds() {
    _lines.clear();
    double? lineHeight;
    final maxBoxWidth = _fixedSize ? width : _boxConfig.maxWidth;

    List<String> charas;
    if (lineBreakInWord) {
      charas = text.characters.toList();
    } else {
      charas = text.split(' ');
    }

    charas.forEach((word) {
      final possibleLine = _lines.isEmpty
          ? word
          : '${_lines.last}${lineBreakInWord ? '' : ' '}$word';
      lineHeight ??= textRenderer.measureTextHeight(possibleLine);

      final textWidth = textRenderer.measureTextWidth(possibleLine);
      if (textWidth <= maxBoxWidth - _boxConfig.margins.horizontal) {
        if (_lines.isNotEmpty) {
          _lines.last = possibleLine;
        } else {
          _lines.add(possibleLine);
        }
        _updateMaxWidth(textWidth);
      } else {
        _lines.add(word);
        _updateMaxWidth(textWidth);
      }
    });
    _totalLines = _lines.length;
    _lineHeight = lineHeight ?? 0.0;
    size = _recomputeSize();
  }

  void _updateMaxWidth(double w) {
    if (w > _maxLineWidth) {
      _maxLineWidth = w;
    }
  }

  double get totalCharTime => text.length * _boxConfig.timePerChar;

  bool get finished => _lifeTime > totalCharTime + _boxConfig.dismissDelay;

  int get _actualTextLength {
    return _lines.map((e) => e.length).sum;
  }

  int get currentChar => _boxConfig.timePerChar == 0.0
      ? _actualTextLength
      : math.min(_lifeTime ~/ _boxConfig.timePerChar, _actualTextLength);

  int get currentLine {
    var totalCharCount = 0;
    final _currentChar = currentChar;
    for (var i = 0; i < _lines.length; i++) {
      totalCharCount += _lines[i].length;
      if (totalCharCount > _currentChar) {
        return i;
      }
    }
    return _lines.length - 1;
  }

  double getLineWidth(String line, int charCount) {
    return textRenderer.measureTextWidth(
      line.substring(0, math.min(charCount, line.length)),
    );
  }

  Vector2 _recomputeSize() {
    if (_fixedSize) {
      return size;
    } else if (_boxConfig.growingBox) {
      var i = 0;
      var totalCharCount = 0;
      final _currentChar = currentChar;
      final _currentLine = currentLine;
      final textWidth = _lines.sublist(0, _currentLine + 1).map((line) {
        final charCount =
            (i < _currentLine) ? line.length : (_currentChar - totalCharCount);
        totalCharCount += line.length;
        i++;
        return getLineWidth(line, charCount);
      }).reduce(math.max);
      return Vector2(
        textWidth + _boxConfig.margins.horizontal,
        // _lineHeight * _lines.length + _boxConfig.margins.vertical,
        _lineHeight * (_currentLine + 1) + _boxConfig.margins.vertical,
      );
    } else {
      return Vector2(
        _boxConfig.maxWidth + _boxConfig.margins.horizontal,
        _lineHeight * _totalLines + _boxConfig.margins.vertical,
      );
    }
  }

  @override
  void render(Canvas c) {
    if (cache == null) {
      return;
    }
    c.save();
    c.scale(1 / pixelRatio);
    c.drawImage(cache!, Offset.zero, _imagePaint);
    c.restore();
  }

  Future<Image> _fullRenderAsImage(Vector2 size) {
    final recorder = PictureRecorder();
    final c = Canvas(recorder, size.toRect());
    c.scale(pixelRatio);
    _fullRender(c);
    return recorder.endRecording().toImageSafe(
          (width * pixelRatio).ceil(),
          (height * pixelRatio).ceil(),
        );
  }

  /// Override this method to provide a custom background to the text box.
  void drawBackground(Canvas c) {}

  void _fullRender(Canvas canvas) {
    drawBackground(canvas);

    final nLines = currentLine + 1;
    final boxWidth = size.x - boxConfig.margins.horizontal;
    final boxHeight = size.y - boxConfig.margins.vertical;
    var charCount = 0;
    for (var i = 0; i < nLines; i++) {
      var line = _lines[i];
      if (i == nLines - 1) {
        final nChars = math.min(currentChar - charCount, line.length);
        line = line.substring(0, nChars);
      }
      textRenderer.render(
        canvas,
        line,
        Vector2(
          boxConfig.margins.left +
              (boxWidth - textRenderer.measureTextWidth(line)) * align.x,
          boxConfig.margins.top +
              (boxHeight - nLines * _lineHeight) * align.y +
              i * _lineHeight,
        ),
      );
      charCount += _lines[i].length;
    }
  }

  Future<void> redraw() async {
    final newSize = _recomputeSize();
    final cachedImage = cache;
    if (cachedImage != null) {
      // Do not dispose of the cached image immediately, since it may have been
      // sent into the rendering pipeline where it is still pending to be used.
      // See issue #1618 for details.
      Future.delayed(const Duration(milliseconds: 100), cachedImage.dispose);
    }
    cache = await _fullRenderAsImage(newSize);
    size = newSize;
  }

  @override
  void update(double dt) {
    _lifeTime += dt;
    if (_previousChar != currentChar) {
      redraw();
      if (text.length > currentChar) {
        onDrawChara?.call(text.substring(currentChar, currentChar + 1));
      }
    }
    if (finished && !isCalledFinish) {
      isCalledFinish = true;
      onFinish?.call();
    }
    _previousChar = currentChar;
  }

  @override
  @mustCallSuper
  void onRemove() {
    super.onRemove();
    cache?.dispose();
    cache = null;
  }
}
