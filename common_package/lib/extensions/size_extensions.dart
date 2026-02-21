import 'package:flutter/material.dart';

extension SizeExtensions on BuildContext{

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  double get bodyHeight {
    Size size = mediaQuery.size;
    double statusBar = mediaQuery.viewPadding.top;
    // double kLeadingWidth = kToolbarHeight;
    double bottomBar = mediaQuery.viewInsets.bottom;
    double bottomPadding = mediaQuery.viewPadding.bottom;
    double bottomSafeArea = mediaQuery.padding.bottom;
    return size.height - statusBar /*- kLeadingWidth*/ - bottomBar - bottomPadding - bottomSafeArea;
  }


  Size size() => MediaQuery.of(this).size;

  /// return screen width
  double get width => MediaQuery.of(this).size.width;

  /// return screen height
  double get  height => MediaQuery.of(this).size.height;

  /// return screen devicePixelRatio
  double get  pixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// returns brightness
  Brightness get  platformBrightness => MediaQuery.of(this).platformBrightness;

  /// Return the height of status bar
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// Return the height of navigation bar
  double get navigationBarHeight => MediaQuery.of(this).padding.bottom;
}