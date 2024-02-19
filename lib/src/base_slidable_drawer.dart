// ignore_for_file: unused_element

part of '../slidable_drawer.dart';

class _BaseSlidableDrawer extends StatefulWidget {
  final Widget child;
  final Widget drawerBody;
  final double? drawerWidth;
  final SwipeDirection swipeDirection;
  final SlidableDrawerController? innerDrawerController;
  final double scaleValue;

  const _BaseSlidableDrawer({
    super.key,
    required this.child,
    required this.drawerBody,
    required this.swipeDirection,
    required this.drawerWidth,
    required this.innerDrawerController,
    required this.scaleValue,
  });

  @override
  State<_BaseSlidableDrawer> createState() => BaseSlidableDrawerState();
}

class BaseSlidableDrawerState extends State<_BaseSlidableDrawer> with SingleTickerProviderStateMixin {
  late double _drawerValue;
  late double _initialWidth;
  double _opacityValue = 0.0;
  late AnimationController _controller;
  late Animation _animation;
  VelocityTracker _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.innerDrawerController?.attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.swipeDirection == SwipeDirection.leftToRight) {
      _drawerValue = -(widget.drawerWidth ?? MediaQuery.sizeOf(context).width * widget.scaleValue);
    } else {
      _drawerValue = widget.drawerWidth ?? MediaQuery.sizeOf(context).width * widget.scaleValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SlidableDrawerController>(
      create: (context) => SlidableDrawerController(),
      child: Consumer<SlidableDrawerController>(
        builder: (context, value, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              _initialWidth = widget.drawerWidth ??
                  constraints.maxWidth * ((widget.swipeDirection == SwipeDirection.leftToRight) ? widget.scaleValue : widget.scaleValue);
              return GestureDetector(
                onTapUp: (details) {
                  // This callback is triggered when the user taps on the screen.

                  if (_drawerValue == 0 && !_isInDrawerBody(details.localPosition)) {
                    // Check if the drawer is fully open (_drawerValue == 0) and the tap is not within the drawer body.
                    // If both conditions are met, animate the drawer to close.
                    animateToClose();
                  }
                },
                onHorizontalDragUpdate: (details) {
                  // This callback is triggered when the user performs a horizontal drag gesture.

                  _velocityTracker.addPosition(details.sourceTimeStamp ?? const Duration(), details.globalPosition);
                  // Add the current position of the drag to the velocity tracker.

                  setState(() {
                    if (widget.swipeDirection == SwipeDirection.leftToRight) {
                      _drawerValue += details.delta.dx;
                      _drawerValue = _drawerValue.clamp(-_initialWidth, 0);
                      _opacityValue = (_drawerValue + _initialWidth) / _initialWidth;
                    } else {
                      _drawerValue += details.delta.dx.abs();
                      _drawerValue = _drawerValue.clamp(0, _initialWidth);
                      _opacityValue = 1 - (_drawerValue / _initialWidth);
                    }
                  });
                },
                onHorizontalDragEnd: (details) {
                  // This callback is triggered when the horizontal drag gesture ends.

                  _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
                  // Reset the velocity tracker to start tracking a new gesture.

                  if (widget.swipeDirection == SwipeDirection.leftToRight) {
                    if (details.velocity.pixelsPerSecond.dx < -1500 && (_drawerValue < 0)) {
                      // Check if the velocity of the drag gesture is greater than -1500 pixels per second and the drawer is currently open.
                      // If both conditions are met, animate the drawer to close.
                      animateToClose();
                    } else {
                      if (details.velocity.pixelsPerSecond.dx > 1500 || _drawerValue > -(_initialWidth / 2)) {
                        // Check if the velocity of the drag gesture is greater than 1500 pixels per second
                        // or the drawer is open beyond half of its initial width (_drawerValue > -(_initialWidth / 2)).
                        // If either condition is met, animate the drawer to open.
                        animateToOpen();
                      } else {
                        // If none of the above conditions are met, animate the drawer to close.
                        animateToClose();
                      }
                    }
                  } else {
                    if (details.velocity.pixelsPerSecond.dx < -1500 && (_drawerValue > 0)) {
                      // Check if the velocity of the drag gesture is greater than -1500 pixels per second and the drawer is currently open.
                      // If both conditions are met, animate the drawer to close.
                      animateToClose();
                    } else {
                      if (details.velocity.pixelsPerSecond.dx > 1500 || _drawerValue < (_initialWidth / 2)) {
                        // Check if the velocity of the drag gesture is greater than 1500 pixels per second
                        // or the drawer is open beyond half of its initial width (_drawerValue > -(_initialWidth / 2)).
                        // If either condition is met, animate the drawer to open.
                        animateToOpen();
                      } else {
                        // If none of the above conditions are met, animate the drawer to close.
                        animateToClose();
                      }
                    }
                  }
                },
                child: Stack(
                  // A widget that stacks its children on top of each other.
                  children: <Widget>[
                    // Main content
                    Container(
                      // A container widget that provides a rectangular visual surface.
                      color: Colors.transparent,
                      // Sets the color of the main content to be transparent.
                      child: widget.child,
                      // Displays the main content provided by the user.
                    ),

                    // Custom drawer
                    Visibility(
                      // A widget that controls the visibility of its child based on a boolean value.
                      visible: (widget.swipeDirection == SwipeDirection.leftToRight) ? _drawerValue != -_initialWidth : _drawerValue != _initialWidth,
                      // Determines whether the custom drawer should be visible or not.
                      child: Container(
                        // A container widget that provides a rectangular visual surface.
                        color: Colors.black.withOpacity(_opacityValue < 0.3 ? _opacityValue : 0.3),
                        // Sets the color of the custom drawer to be black with an opacity value that depends on `_opacityValue` (clamped between 0 and 0.3).
                      ),
                    ),

                    Visibility(
                      // A widget that controls the visibility of its child based on a boolean value.
                      visible: (widget.swipeDirection == SwipeDirection.leftToRight) ? _drawerValue != -_initialWidth : _drawerValue != _initialWidth,
                      // Determines whether the custom drawer should be visible or not.
                      child: Transform.translate(
                        // A widget that applies a translation transformation to its child.
                        offset: Offset(_drawerValue, 0.0),
                        // Specifies the translation offset for the custom drawer.
                        child: SizedBox(
                          // A box widget with a specified width and height.
                          width: widget.drawerWidth ?? MediaQuery.sizeOf(context).width * widget.scaleValue,
                          // Sets the width of the custom drawer to either the provided `widget.drawerWidth` value or 75% of the screen width if it is not provided.
                          child: widget.drawerBody,
                          // Displays the custom drawer body provided by the user.
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// This function checks if the tapped position is within the body of the drawer.
  /// It takes an Offset parameter representing the position of the tap.
  /// It returns a boolean value indicating whether the tap position is within the drawer body.
  bool _isInDrawerBody(Offset tapPosition) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    // Retrieve the RenderBox associated with the current context.

    double drawerBodyLeft = renderBox.localToGlobal(Offset.zero).dx + _drawerValue;
    // Get the left coordinate of the drawer body by converting the local offset (0, 0)
    // to a global offset and adding the current drawer value.

    double drawerBodyRight = drawerBodyLeft + (widget.drawerWidth ?? MediaQuery.sizeOf(context).width * widget.scaleValue);
    // Get the right coordinate of the drawer body by adding the width of the drawer to the left coordinate.
    // If the widget has a specified drawer width, use it. Otherwise, calculate the default width based on the device's screen size.

    return tapPosition.dx >= drawerBodyLeft && tapPosition.dx <= drawerBodyRight;
    // Return true if the x-coordinate of the tap position is within the range of the drawer body's left and right coordinates.
  }

  /// This function animates the drawer to the open state.
  void animateToOpen() {
    if (widget.swipeDirection == SwipeDirection.leftToRight) {
      // Анимация для LeftToRight
      _animation = Tween<double>(begin: _drawerValue, end: 0.0).animate(_controller);
    } else {
      // Анимация для RightToLeft должна начинаться с текущего _drawerValue и идти к 0
      _animation = Tween<double>(begin: _drawerValue, end: MediaQuery.of(context).size.width - _initialWidth).animate(_controller);
    }

    _animation.addListener(() {
      setState(() {
        _drawerValue = _animation.value;
        _opacityValue = 1.0 - (_drawerValue.abs() / _initialWidth);
      });
    });

    _controller.reset();
    _controller.forward();
  }

  /// This function animates the drawer to the closed state.
  void animateToClose() {
    if (widget.swipeDirection == SwipeDirection.leftToRight) {
      // Анимация для LeftToRight
      _animation = Tween<double>(begin: _drawerValue, end: -_initialWidth).animate(_controller);
    } else {
      // Анимация для RightToLeft должна начинаться с 0 и идти к начальному положению (_initialWidth)
      _animation = Tween<double>(begin: _drawerValue, end: _initialWidth).animate(_controller);
    }
    _animation.addListener(() {
      setState(() {
        _drawerValue = _animation.value;
        _opacityValue = (1.0 - (_drawerValue.abs() / _initialWidth)).clamp(0.0, 1.0);
      });
    });

    _controller.reset();
    _controller.forward();
  }
}
