# animated_transform_widget
flutter中常用简单动画（平移、旋转、缩放、隐藏显示）的封装。
[github项目地址](https://github.com/messnoTrace/AnimaitonContainer)
[pub_dev](https://pub.dev/packages/animated_transform_widget)

## 用法：
* 直接播放动画：
```
AnimatedTransformContainer.single(
              fromScale: 0.1,
              toScale: 1.0,
              curve: Curves.easeOutQuint,
              duration: Duration(milliseconds: 600),
              delayed: Duration(milliseconds: 300),
              child: Container(
      
                ),
              ),
            )
```
* 通过行为控制动画
```
  final GlobalKey<AnimatedTransformState> yourKey =
      GlobalKey<AnimatedTransformState>();
AnimatedTransformContainer.director(
        key: yourKey,
        height: height,
        showAfterStarted: true,
        width: width,
        child: Container());


     yourKey.currentState.scheduleAnimations([
                    TransformAnimation(
                        fromScale: 0.3,
                        toScale: 1.0,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.linear)
                  ]);
```
