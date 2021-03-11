import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ValueRef<T> {
  T value;

  ValueRef(this.value);
}

typedef Filter<T> = bool Function(T);


typedef ContextCallback = void Function(BuildContext);

typedef ContextValueGetter<T> = T Function(BuildContext);

typedef ParamsCallback<T> = void Function(T);

typedef BoolCallback = bool Function();

typedef Checker<T> = bool Function(T);

typedef FutureCallback<T> = Future<T> Function();

class Utils {
  static final _ASCII_A = "A".codeUnitAt(0);
  static final _ASCII_0 = "0".codeUnitAt(0);
  static final _ASCII_9 = "9".codeUnitAt(0);
  static final _ASCII_DOT = ".".codeUnitAt(0);

  static T constraintValue<T extends num>(T value, T minValue, T maxValue) {
    return min(max(value, minValue), maxValue);
  }

  static double toRadian(double angle) {
    return angle * (pi / 180);
  }

  static double toAngle(double radian) {
    return radian * (180 / pi);
  }

  static int toColorValue(String colorStr, {Color defaultColor = Colors.white}) {
    if (colorStr == null) {
      return defaultColor.value;
    }
    String colorValue = colorStr.toUpperCase().replaceAll("#", "");
    if (colorValue.length == 3) {
      return Color.fromARGB(
              0xFF,
              (((colorValue[0].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt(),
              (((colorValue[1].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt(),
              (((colorValue[2].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt())
          .value;
    }
    if (colorValue.length == 6) {
      colorValue = "FF" + colorValue;
    }

    return int.parse(colorValue, radix: 16);
  }

  static Color toColor(String colorStr, {Color defaultColor = Colors.white}) {
    if (colorStr == null) {
      return defaultColor;
    }
    String colorValue = colorStr.toUpperCase().replaceAll("#", "");
    if (colorValue.length == 3) {
      return Color.fromARGB(
          0xFF,
          (((colorValue[0].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt(),
          (((colorValue[1].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt(),
          (((colorValue[2].codeUnitAt(0) - _ASCII_A) / 0x0F) * 0xFF).toInt());
    }
    if (colorValue.length == 6) {
      colorValue = "FF" + colorValue;
    }

    return Color(int.parse(colorValue, radix: 16));
  }

  static int compareVersion(String version1, String version2) {
    if (version1 == version2) {
      return 0;
    }
    final version1Array = version1.split(".");
    final version2Array = version2.split(".");

    int minLen = min(version1Array.length, version2.length);
    int diff = 0;
    int index = 0;
    while (index < minLen &&
        (diff = int.parse(version1Array[index]) - int.parse(version2Array[index])) == 0) {
      index++;
    }
    if (diff == 0) {
      for (int i = index; i < version1Array.length; i++) {
        if (int.parse(version1Array[i]) > 0) {
          return 1;
        }
      }
      for (int i = index; i < version2Array.length; i++) {
        if (int.parse(version2Array[i]) > 0) {
          return -1;
        }
      }
      return 0;
    } else {
      return diff > 0 ? 1 : -1;
    }
  }

  static Function debounce(
    Function func, [
    Duration delay = const Duration(milliseconds: 2000),
  ]) {
    Timer timer;
    Function target = () {
      if (timer?.isActive ?? false) {
        timer?.cancel();
      }
      timer = Timer(delay, () {
        func?.call();
      });
    };
    return target;
  }

  static Function throttle(Future Function() func) {
    if (func == null) {
      return func;
    }
    bool enable = true;
    Function target = () {
      if (enable == true) {
        func().then((_) {
          enable = false;
        });
        Future.delayed(Duration(milliseconds: 500), () => enable = true);
      }
    };
    return target;
  }

  static void safeRun(VoidCallback callback) {
    try {
      callback();
    } catch (error, stacktrace) {}
  }

  static List<num> extractNumbers(String text) {
    int currentIndex = 0;
    bool hasDot = false;
    final result = <num>[];
    String numString = "";
    void _generate() {
      try {
        if (hasDot) {
          result.add(double.parse(numString));
        } else {
          result.add(int.parse(numString));
        }
      } catch (error) {
        print("parse num error! $numString");
      }
    }

    while (currentIndex < text.length) {
      final c = text.codeUnitAt(currentIndex);
      if (c == _ASCII_DOT && !hasDot) {
        if (numString.length == 0) {
          numString += "0.";
        } else {
          numString += ".";
        }
        hasDot = true;
      } else if ((c >= _ASCII_0 && c <= _ASCII_9)) {
        numString += text[currentIndex];
      } else if (numString.length > 0) {
        _generate();
        hasDot = false;
        numString = "";
      }
      ++currentIndex;
    }
    if (numString.length > 0) {
      _generate();
    }
    return result;
  }

  static List<String> extractNumberStrings(String text) {
    int currentIndex = 0;
    bool hasDot = false;
    final result = <String>[];
    String numString = "";
    while (currentIndex < text.length) {
      final c = text.codeUnitAt(currentIndex);
      if (c == _ASCII_DOT && !hasDot) {
        if (numString.length == 0) {
          numString += "0.";
        } else {
          numString += ".";
        }
        hasDot = true;
      } else if ((c >= _ASCII_0 && c <= _ASCII_9)) {
        numString += text[currentIndex];
      } else if (numString.length > 0) {
        result.add(numString);
        hasDot = false;
        numString = "";
      }
      ++currentIndex;
    }
    if (numString.length > 0) {
      result.add(numString);
    }
    return result;
  }

  static String extractFirstNumberString(String text) {
    int currentIndex = 0;
    bool hasDot = false;
    final length = text?.length ?? 0;
    String numString = "";
    while (currentIndex < length) {
      final c = text.codeUnitAt(currentIndex);
      if (c == _ASCII_DOT && !hasDot) {
        if (numString.length == 0) {
          numString += "0.";
        } else {
          numString += ".";
        }
        hasDot = true;
      } else if ((c >= _ASCII_0 && c <= _ASCII_9)) {
        numString += text[currentIndex];
      } else if (numString.length > 0) {
        return numString;
      }
      ++currentIndex;
    }
    if (numString.length > 0) {
      return numString;
    }
    return null;
  }

  static String getPlatformName() {
    if (Platform.isAndroid) {
      return "android";
    } else if (Platform.isIOS) {
      return "ios";
    } else if (Platform.isFuchsia) {
      return "fuchsia";
    } else if (Platform.isMacOS) {
      return "macos";
    } else if (Platform.isWindows) {
      return "windows";
    } else {
      return "linux";
    }
  }
}
