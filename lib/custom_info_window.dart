/// A widget based custom info window for google_maps_flutter package.
library custom_info_window;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller to add, update and control the custom info window.
class CustomInfoWindowController {
  /// Add custom [Widget] and [Marker]'s [LatLng] to [CustomInfoWindow] and make it visible.
  /// Offset to maintain space between [Marker] and [CustomInfoWindow].
  /// Height of [CustomInfoWindow].
  /// Width of [CustomInfoWindow].
  Function(Widget, LatLng, double, double, double)? addInfoWindow;

  /// Notifies [CustomInfoWindow] to redraw as per change in position.
  VoidCallback? onCameraMove;

  /// Hides [CustomInfoWindow].
  VoidCallback? hideInfoWindow;

  /// Shows [CustomInfoWindow].
  VoidCallback? showInfoWindow;

  /// Holds [GoogleMapController] for calculating [CustomInfoWindow] position.
  GoogleMapController? googleMapController;

  final Duration animationDuration;

  final Curve animationCurve;

  CustomInfoWindowController({
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut
  });

  void dispose() {
    addInfoWindow = null;
    onCameraMove = null;
    hideInfoWindow = null;
    showInfoWindow = null;
    googleMapController = null;
  }
}

/// A stateful widget responsible to create widget based custom info window.
class CustomInfoWindow extends StatefulWidget{
  /// A [CustomInfoWindowController] to manipulate [CustomInfoWindow] state.
  final CustomInfoWindowController controller;

  final Function(double top, double left, double width, double height) onChange;

  

  const CustomInfoWindow(
    this.onChange, {
    required this.controller,
  });

  @override
  _CustomInfoWindowState createState() => _CustomInfoWindowState();
}

class _CustomInfoWindowState extends State<CustomInfoWindow> with TickerProviderStateMixin {
  bool _showNow = false;
  double _leftMargin = 0;
  double _topMargin = 0;
  Widget? _child;
  LatLng? _latLng;
  double _offset = 50;
  double _height = 50;
  double _width = 100;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
    widget.controller.hideInfoWindow = _hideInfoWindow;
    widget.controller.showInfoWindow = _showInfoWindow;

    _animController = AnimationController(vsync: this, duration: widget.controller.animationDuration);
    _animController.addListener(_animListener);
  }

  void _animListener() {
    setState(() {
    });
  }

  /// Calculate the position on [CustomInfoWindow] and redraw on screen.
  void _updateInfoWindow() async {
    if (_latLng == null ||
        _child == null ||
        widget.controller.googleMapController == null) {
      return;
    }
    ScreenCoordinate screenCoordinate = await widget
        .controller.googleMapController!
        .getScreenCoordinate(_latLng!);
    double devicePixelRatio =
        Theme.of(context).platform == TargetPlatform.android ? MediaQuery.of(context).devicePixelRatio : 1.0;
    double left =
        (screenCoordinate.x.toDouble() / devicePixelRatio) - (_width / 2);
    double top = (screenCoordinate.y.toDouble() / devicePixelRatio) -
        (_offset + _height);
    setState(() {
      _showNow = true;
      _leftMargin = left;
      _topMargin = top;
      _animController.forward();
    });
    widget.onChange.call(top, left, _width, _height);
  }

  /// Assign the [Widget] and [Marker]'s [LatLng].
  void _addInfoWindow(Widget child, LatLng latLng, double offset, double height, double width) {
    _child = child;
    _latLng = latLng;
    _offset = offset;
    _height = height;
    _width = width;
    _updateInfoWindow();
  }

  /// Notifies camera movements on [GoogleMap].
  void _onCameraMove() {
    if (!_showNow) return;
    _updateInfoWindow();
  }

  /// Disables [CustomInfoWindow] visibility.
  void _hideInfoWindow() {
    setState(() {
      _showNow = false;
      _animController.reverse();
    });
  }

  /// Enables [CustomInfoWindow] visibility.
  void _showInfoWindow() {
    _updateInfoWindow();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _leftMargin,
      top: _topMargin,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animController, curve: widget.controller.animationCurve, reverseCurve: widget.controller.animationCurve)
        ),
        child: Opacity(
          opacity: _animController.value,
          child: SizedBox(
            height: _height,
            width: _width,
            child: _child,
          ),
        ),
      ),
    );
  }
}
