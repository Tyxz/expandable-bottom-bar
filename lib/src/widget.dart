import 'dart:math' show max, min;

import 'package:expandable_bottom_bar/src/controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Side { Top, Bottom }

class BottomExpandableAppBar extends StatefulWidget {
  final Widget expandedBody;
  final double expandedHeight;
  final Widget bottomAppBarBody;
  final BottomBarController controller;
  final Side attachSide;

  final double appBarHeight;
  // TODO: Get max available height
  final bool useMax;

  final BoxConstraints constraints;

  final NotchedShape shape;
  final Color expandedBackColor;
  final Color bottomAppBarColor;
  final double horizontalMargin;
  final double bottomOffset;

  final Decoration expandedDecoration;
  final Decoration appBarDecoration;

  /// Elevation value of the expanded app bar to comply to material design guide lines.
  /// The following elevations are possible:
  /// 1, 2, 3, 4, 6, 8, 12
  /// The app bar will have twice the elevation
  /// Will only work with [appBarDecoration] = null or [expandedDecoration] = null
  final double elevation;

  /// Margin of the notch to the fab
  final double notchMargin;

  /// Transition rate of the expanding bottom app bar
  /// value < 1.0 will result in a at least partly transparent background
  /// best used together with with [snap] = true in the controller settings
  final double transitionRate;

  /// Handles, if the transition between a closed and opened app bar will
  /// be transparent. It is based on the controller animation value.
  /// Therefore, best used with [snap] = true.
  /// Otherwise, partly transparency will be the result.
  /// Also, it should be set together with [bottomOffset] = 0.
  final bool transparentTransition;

  BottomExpandableAppBar({
    Key key,
    this.expandedBody,
    this.horizontalMargin: 16,
    this.bottomOffset: 10,
    this.shape,
    this.expandedHeight: 150,
    this.appBarHeight: 50,
    this.attachSide: Side.Bottom,
    this.constraints,
    this.bottomAppBarColor,
    this.appBarDecoration,
    this.bottomAppBarBody,
    this.expandedBackColor,
    this.expandedDecoration,
    this.controller,
    this.useMax: false,
    this.elevation = 0,
    this.notchMargin = 5,
    this.transparentTransition: false,
    this.transitionRate = 2,
  })  : assert(!(expandedBackColor != null && expandedDecoration != null)),
        assert(!(bottomAppBarColor != null && appBarDecoration != null)),
        super(key: key);

  @override
  _BottomExpandableAppBarState createState() => _BottomExpandableAppBarState();
}

class _BottomExpandableAppBarState extends State<BottomExpandableAppBar> {
  BottomBarController _controller;
  double panelState;

  void _handleBottomBarControllerAnimationTick() {
    if (_controller.state.value == panelState) return;
    panelState = _controller.state.value;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBarController();
    panelState = _controller?.state?.value ?? panelState;
  }

  @override
  void didUpdateWidget(BottomExpandableAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) _updateBarController();
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.state.removeListener(_handleBottomBarControllerAnimationTick);
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  void _updateBarController() {
    final BottomBarController newController =
        widget.controller ?? DefaultBottomBarController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError('No BottomBarController for ${widget.runtimeType}.\n'
            'When creating a ${widget.runtimeType}, you must either provide an explicit '
            'BottomBarController using the "controller" property, or you must ensure that there '
            'is a DefaultBottomBarController above the ${widget.runtimeType}.\n'
            'In this case, there was neither an explicit controller nor a default controller.');
      }
      return true;
    }());

    if (newController == _controller) return;

    if (_controller != null) {
      _controller.state.removeListener(_handleBottomBarControllerAnimationTick);
    }
    _controller = newController;
    if (_controller != null) {
      _controller.state.addListener(_handleBottomBarControllerAnimationTick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalHeight = (widget.useMax && widget.constraints != null)
        ? widget.constraints.biggest.height
        : widget.expandedHeight;
    final expandedElevation = min(12, widget.elevation);
    final barElevation = min(24, expandedElevation * 2);
    return BottomAppBar(
      color: Colors.transparent,
      notchMargin: widget.notchMargin,
      //elevation: widget.elevation,
      child: Stack(
        //TODO: Find out how to get top app bar overlap body content of scaffold
        alignment: widget.attachSide == Side.Bottom
            ? Alignment.bottomCenter
            : Alignment.topCenter,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.horizontalMargin ?? 0),
            child: Stack(
              children: [
                Opacity(
                  opacity: widget.transparentTransition
                      ? max(
                          0,
                          min(1, widget.transitionRate * panelState),
                        )
                      : 1,
                  child: Container(
                    height: panelState * finalHeight +
                        widget.appBarHeight +
                        widget.bottomOffset,
                    decoration: widget.expandedDecoration ??
                        BoxDecoration(
                          color: widget.expandedBackColor ??
                              Theme.of(context).backgroundColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: kElevationToShadow[expandedElevation],
                        ),
                    child: Opacity(
                        opacity: panelState > 0.25 ? 1 : panelState * 4,
                        child: widget.expandedBody),
                  ),
                ),
              ],
            ),
          ),
          // * Mask content of bottom container in notch
          Container(
            // some mask code
            height: widget.appBarHeight,
          ),
          ClipPath(
            child: Container(
              decoration: widget.appBarDecoration ??
                  BoxDecoration(
                    color: widget.bottomAppBarColor ??
                        Theme.of(context).bottomAppBarColor,
                    boxShadow: kElevationToShadow[barElevation],
                  ),
              height: widget.appBarHeight,
              child: widget.bottomAppBarBody,
            ),
            clipper: widget.shape != null
                ? _BottomAppBarClipper(
                    geometry: Scaffold.geometryOf(context),
                    shape: widget.shape,
                    notchMargin: widget.notchMargin,
                    buttonOffset: widget.bottomOffset,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

//Copied from flutter sdk
class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper(
      {@required this.geometry,
      @required this.shape,
      @required this.notchMargin,
      @required this.buttonOffset})
      : assert(geometry != null),
        assert(shape != null),
        assert(notchMargin != null),
        super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final double notchMargin;
  final double buttonOffset;

  @override
  Path getClip(Size size) {
    // button is the floating action button's bounding rectangle in the
    // coordinate system whose origin is at the appBar's top left corner,
    // or null if there is no floating action button.
    final Rect button = geometry.value.floatingActionButtonArea?.translate(
      0.0,
      geometry.value.bottomNavigationBarTop * -1.0 - buttonOffset,
    );
    return shape.getOuterPath(
        Offset(0, 0) & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) {
    return oldClipper.geometry != geometry ||
        oldClipper.shape != shape ||
        oldClipper.notchMargin != notchMargin;
  }
}
