library animated_transform_widget;

import 'dart:async';
import 'dart:collection';

import 'package:animated_transform_widget/utils.dart';
import 'package:flutter/cupertino.dart';

import 'curves_ext.dart';

int infinite = -1;

class TransformAnimation {
  static const int infinite = -1;
  final Duration delayed;
  final Duration duration;
  final Duration interval;
  final int intervalCount;
  final Offset fromTranslation;
  final Offset toTranslation;
  final double fromOpacity;
  final double toOpacity;
  final double fromScale;
  final double toScale;
  final double fromXScale;
  final double toXScale;
  final double fromYScale;
  final double toYScale;

  final double fromColorOpacity;
  final double toColorOpacity;
  final double fromAngle;
  final double toAngle;
  final Curve curve;
  final Curve reverseCurve;
  final OffsetCurve translationCurve;
  final int repeat;
  final bool reverse;
  final bool medianPending;

  final VoidCallback onCompleted;

  TransformAnimation(
      {this.delayed = const Duration(milliseconds: 0),
      this.duration = const Duration(milliseconds: 800),
      this.repeat = 0,
      this.interval = const Duration(milliseconds: 0),
      this.intervalCount = 1,
      this.medianPending = false,
      this.reverse = false,
      this.curve = Curves.linear,
      this.translationCurve,
      this.reverseCurve = Curves.linear,
      this.fromOpacity = 1.0,
      this.toOpacity = 1.0,
      this.fromTranslation = Offset.zero,
      this.toTranslation = Offset.zero,
      this.fromAngle = 0.0,
      this.toAngle = 0.0,
      this.fromColorOpacity = 1.0,
      this.toColorOpacity = 1.0,
      this.fromScale = 1.0,
      this.toScale = 1.0,
      this.fromXScale,
      this.toXScale,
      this.fromYScale,
      this.toYScale,
      this.onCompleted});
}

enum AnimatorState { pending, started, disposed }

class _Animator {
  final AnimationController controller;
  final TransformAnimation animation;
  final Key widgetKey;
  Animation<double> _scaleAnimation;
  Animation<double> _scaleXAnimation;
  Animation<double> _scaleYAnimation;
  Animation<double> _translationXAnimation;
  Animation<double> _translationYAnimation;
  Animation<double> _rotationAnimation;
  Animation<double> _opacityAnimation;
  Animation<double> _colorOpacityAnimation;
  Offset _translationOffset;
  VoidCallback onCompleted;
  VoidCallback onStarted;
  int _repeatCount = 0;
  Matrix4 matrix = Matrix4.identity();

  Timer _intervalTimer;
  Timer _delayedTimer;

  AnimatorState _state = AnimatorState.pending;

  bool get isStarted => _state == AnimatorState.started;

  bool get isDisposed => _state == AnimatorState.disposed;

  bool _scheduleRepeat() {
    if (animation.repeat == infinite || _repeatCount < animation.repeat) {
      _repeatCount++;
      final forward = !animation.reverse || (_repeatCount & 0x01 != 1);
      if (animation.interval.inMilliseconds > 0 && (_repeatCount % animation.intervalCount == 0)) {
        _intervalTimer?.cancel();
        _intervalTimer = Timer(animation.interval, () {
          if (!isDisposed) {
            if (forward) {
              _forward(from: 0);
            } else {
              _reverse(from: 1);
            }
          }
        });
      } else {
        if (forward) {
          _forward(from: 0);
        } else {
          _reverse(from: 1);
        }
      }
      return true;
    }
    return false;
  }

  void _forward({double from}) {
    try {
      controller?.forward(from: from);
    } catch (error) {}
  }

  void _reverse({double from}) {
    try {
      controller?.reverse(from: from);
    } catch (error) {}
  }

  void dispatchCompleted() {
    animation.onCompleted?.call();
    if (onCompleted != null) {
      onCompleted.call();
      onCompleted = null;
    }
  }

  void handleAnimationStateChanged(AnimationStatus status) {
    // print("handleAnimationStateChanged[$widgetKey]: $status");

    if (isDisposed) {
      return;
    }
    bool repeat = false;
    if (status == AnimationStatus.completed) {
      repeat = _scheduleRepeat();
    } else if (status == AnimationStatus.dismissed) {
      repeat = _scheduleRepeat();
    }
    if (!repeat && (status == AnimationStatus.completed || status == AnimationStatus.dismissed)) {
      print("completed!!");
      dispatchCompleted();
    }
  }

  Matrix4 _refreshMatrix(BoxConstraints constraints) {
    final translationX =
        animation.translationCurve != null ? _translationOffset.dx : _translationXAnimation.value;
    final translationY =
        animation.translationCurve != null ? _translationOffset.dy : _translationYAnimation.value;
    final radian = _rotationAnimation.value;

    final Matrix4 _matrix = Matrix4.identity();
    _matrix.translate(translationX, translationY);
    _matrix.translate(constraints.maxWidth / 2, constraints.maxHeight / 2);
    if (animation.fromAngle != 0 || animation.toAngle != 0) {
      _matrix.rotateZ(radian);
    }

    if ((animation.fromXScale != null && animation.toXScale != null) ||
        (animation.fromYScale != null && animation.toYScale != null)) {
      _matrix.scale(_scaleXAnimation.value, _scaleYAnimation.value);
    } else if (animation.fromScale != 0 || animation.toScale != 0) {
      final scale = _scaleAnimation.value;
      _matrix.scale(scale, scale);
    }
    _matrix.translate(-constraints.maxWidth / 2, -constraints.maxHeight / 2);
    matrix = _matrix;
    return _matrix;
  }

  double _refreshOpacity() {
    if (animation.fromOpacity == animation.toOpacity) {
      return animation.toOpacity;
    }
    return Utils.constraintValue(_opacityAnimation.value, 0.0, 1.0);
  }

  Color _refreshColorOpacity(Color color) {
    if (color == null) {
      return null;
    }
    if (animation.fromColorOpacity == animation.toColorOpacity) {
      return color.withOpacity(animation.toColorOpacity);
    }
    return color.withOpacity(Utils.constraintValue(_colorOpacityAnimation.value, 0.0, 1.0));
  }

  _Animator.schedule(this.animation,
      {@required TickerProvider vsync,
      this.widgetKey,
      AnimatorState initState = AnimatorState.pending,
      this.matrix,
      this.onStarted,
      this.onCompleted})
      : controller = new AnimationController(vsync: vsync, duration: animation.duration) {
    controller.addStatusListener(handleAnimationStateChanged);
    final curved = CurvedAnimation(parent: controller, curve: animation.curve);

    if ((animation.fromXScale != null && animation.toXScale != null) ||
        (animation.fromYScale != null && animation.toYScale != null)) {
      _scaleXAnimation =
          Tween(begin: animation.fromXScale ?? 1.0, end: animation.toXScale ?? 1.0).animate(curved);
      _scaleYAnimation =
          Tween(begin: animation.fromYScale ?? 1.0, end: animation.toYScale ?? 1.0).animate(curved);
    } else {
      _scaleAnimation = Tween(begin: animation.fromScale, end: animation.toScale).animate(curved);
    }
    if (animation.translationCurve == null) {
      _translationXAnimation =
          Tween(begin: animation.fromTranslation.dx, end: animation.toTranslation.dx)
              .animate(curved);
      _translationYAnimation =
          Tween(begin: animation.fromTranslation.dy, end: animation.toTranslation.dy)
              .animate(curved);
    } else {
      _translationOffset = animation.fromTranslation;
      controller.addListener(() {
        _translationOffset = animation.translationCurve.transform(controller.value);
      });
    }

    _rotationAnimation =
        Tween(begin: Utils.toRadian(animation.fromAngle), end: Utils.toRadian(animation.toAngle))
            .animate(curved);
    _opacityAnimation =
        Tween(begin: animation.fromOpacity, end: animation.toOpacity).animate(curved);

    _colorOpacityAnimation =
        Tween(begin: animation.fromColorOpacity, end: animation.toColorOpacity).animate(curved);
    _state = initState;
    if (animation.delayed.inMilliseconds > 0) {
      _delayedTimer?.cancel();
      _delayedTimer = Timer(animation.delayed, () {
        if (!isDisposed) {
          _state = AnimatorState.started;
          controller.forward(from: 0);
          onStarted?.call();
        }
      });
    } else {
      Future.microtask(() {
        controller.forward(from: 0);
        onStarted?.call();
      });
      _state = AnimatorState.started;
    }
  }

  void dispose() {
    print("dispose: $_state $isDisposed");
    if (!isDisposed) {
      _state = AnimatorState.disposed;
      controller.dispose();
      _intervalTimer?.cancel();
      _delayedTimer?.cancel();
//      dispatchCompleted();
    }
  }
}

enum AnimatedBehavior {
  show,
  hide,
}

class AnimatedTransformContainer extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color color;
  final bool showAfterStarted;
  final bool autoPlay;
  final AnimatedBehavior completedBehavior;
  final VoidCallback onCompleted;

  final List<TransformAnimation> animations = [];


  AnimatedTransformContainer.single(
      {Key key,
        this.child,
        this.width,
        this.height,
        this.color,
        this.showAfterStarted = true,
        this.autoPlay = true,
        this.onCompleted,
        this.completedBehavior = AnimatedBehavior.show,
        Duration delayed = const Duration(milliseconds: 0),
        Duration duration = const Duration(milliseconds: 800),
        int repeat = 0,
        Duration interval = const Duration(milliseconds: 0),
        int intervalCount = 1,
        bool reverse = false,
        bool medianPending = false,
        Curve curve = Curves.linear,
        Curve reverseCurve = Curves.linear,
        double fromOpacity = 1.0,
        double toOpacity = 1.0,
        double fromColorOpacity = 1.0,
        double toColorOpacity = 1.0,
        Offset fromTranslation = Offset.zero,
        Offset toTranslation = Offset.zero,
        double fromAngle = 0.0,
        double toAngle = 0.0,
        double fromScale = 1.0,
        double toScale = 1.0,
        double fromXScale,
        double toXScale,
        double fromYScale,
        double toYScale})
      : super(key: key) {
    animations.add(TransformAnimation(
        delayed: delayed,
        duration: duration,
        repeat: repeat,
        interval: interval,
        intervalCount: intervalCount,
        reverse: reverse,
        medianPending: medianPending,
        curve: curve,
        reverseCurve: reverseCurve,
        fromOpacity: fromOpacity,
        toOpacity: toOpacity,
        fromScale: fromScale,
        toScale: toScale,
        fromXScale: fromXScale,
        toXScale: toXScale,
        fromYScale: fromYScale,
        toYScale: toYScale,
        fromAngle: fromAngle,
        toAngle: toAngle,
        fromColorOpacity: fromColorOpacity,
        toColorOpacity: toColorOpacity,
        fromTranslation: fromTranslation,
        toTranslation: toTranslation));
  }

  AnimatedTransformContainer.sequentially(
      {Key key,
        this.child,
        this.width,
        this.height,
        this.color,
        this.showAfterStarted = true,
        this.autoPlay = true,
        this.onCompleted,
        this.completedBehavior = AnimatedBehavior.show,
        List<TransformAnimation> animations})
      : super(key: key) {
    this.animations.addAll(animations);
  }

  AnimatedTransformContainer.director(
      {Key key,
        this.child,
        this.width,
        this.height,
        this.color,
        this.showAfterStarted = false,
        this.autoPlay = true,
        this.completedBehavior = AnimatedBehavior.show,
        this.onCompleted})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AnimatedTransformState();
  }
}
class AnimatedTransformState extends State<AnimatedTransformContainer>
    with TickerProviderStateMixin {
  DoubleLinkedQueue<TransformAnimation> animations = DoubleLinkedQueue();
  _Animator _animator;
  AnimatedBehavior _animatedBehavior = AnimatedBehavior.show;
  AnimatedBehavior _completedBehavior = AnimatedBehavior.show;

  Matrix4 _lastMatrix = Matrix4.identity();

  void _onNext() {
    // print("_onNext ${animations.isEmpty} ${animations.length}");
    if (animations.isEmpty) {
      setState(() {
        _animatedBehavior = _completedBehavior;
      });
      widget.onCompleted?.call();
      return;
    }
    final animation = animations.removeFirst();
    if (animation != null) {
      setState(() {
        _lastMatrix = _animator?.matrix ?? Matrix4.identity();
        _animator?.dispose();
        _animator = _Animator.schedule(animation,
            vsync: this,
            widgetKey: widget.key,
            initState: AnimatorState.started,
            onCompleted: _onNext);
      });
    } else {}
  }

  void play() {
    _onNext();
  }

  void stop({AnimatedBehavior behavior = AnimatedBehavior.show}) {
    setState(() {
      _animator?.dispose();
      _animator = null;
      animations.clear();
      _animatedBehavior = behavior;
    });
  }

  void scheduleAnimations(List<TransformAnimation> transformAnimations,
      {bool append = false, AnimatedBehavior completedBehavior = AnimatedBehavior.show}) {
    _completedBehavior = completedBehavior;
    if (append) {
      bool empty = animations.isEmpty;
      animations.addAll(transformAnimations);
      if (empty) {
        _onNext();
      }
    } else {
      // print("scheduleAnimations ${transformAnimations.length}");
      animations.clear();
      animations.addAll(transformAnimations);
      _onNext();
    }
  }

  @override
  void initState() {
    super.initState();
    animations.addAll(widget.animations);
    if (widget.autoPlay) {
      final animation = animations.isNotEmpty ? animations.removeFirst() : null;
      if (animation != null) {
        _completedBehavior = widget.completedBehavior;
        _animator = _Animator.schedule(animation,
            vsync: this, widgetKey: widget.key, onStarted: () {}, onCompleted: _onNext);
      }
    }
  }

  @override
  void dispose() {
    print("animated_transform_widget dispose ${_animator?.animation?.toAngle}");
    _animator?.dispose();
    _animator = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _animatedBehavior == AnimatedBehavior.hide
        ? SizedBox(width: widget.width, height: widget.height)
        : SizedBox(
      width: widget.width,
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        return _animator == null
            ? (!widget.showAfterStarted
            ? Container(
            color: widget.color,
            child: Center(
              child: Transform(
                transform: _lastMatrix,
                child: widget.child,
              ),
            ))
            : Container())
            : AnimatedBuilder(
            animation: _animator.controller,
            child: widget.child,
            builder: (BuildContext ctx, Widget child) {
              return Center(
                  child: Transform(
                      transform: _animator._refreshMatrix(constraints),
                      child: Opacity(
                          opacity: (!widget.showAfterStarted || _animator.isStarted)
                              ? _animator._refreshOpacity()
                              : 0,
                          child: Container(
                              color: (!widget.showAfterStarted || _animator.isStarted)
                                  ? _animator._refreshColorOpacity(widget.color)
                                  : widget.color,
                              child: child))));
            });
      }),
    );
  }
}
