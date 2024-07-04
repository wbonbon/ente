import "dart:async";

import "package:flutter/widgets.dart";

class PointerProvider extends StatefulWidget {
  final Widget child;
  const PointerProvider({
    super.key,
    required this.child,
  });

  @override
  State<PointerProvider> createState() => _PointerProviderState();
}

class _PointerProviderState extends State<PointerProvider> {
  late Pointer pointer;
  bool _isFingerOnScreenSinceLongPress = false;

  @override
  void dispose() {
    pointer.closeMoveOffsetController();
    pointer.closeUpOffsetStreamController();
    pointer.closeOnTapStreamController();
    pointer.closeOnLongPressStreamController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pointer(
      child: Builder(
        builder: (context) {
          pointer = Pointer.of(context);
          return GestureDetector(
            onTap: () {
              pointer.onTapStreamController.add(pointer.pointerPosition);
            },
            onLongPress: () {
              _isFingerOnScreenSinceLongPress = true;
              pointer.onLongPressStreamController.add(pointer.pointerPosition);
            },
            onHorizontalDragUpdate: (details) {
              pointer.moveOffsetStreamController.add(details.localPosition);
            },
            child: Listener(
              onPointerMove: (event) {
                pointer.pointerPosition = event.localPosition;

                //onHorizontalDragUpdate is not called when dragging after
                //long press without lifting finger. This is for handling only
                //this case.
                if (_isFingerOnScreenSinceLongPress &&
                    (event.localDelta.dx.abs() > 0 &&
                        event.localDelta.dy.abs() > 0)) {
                  pointer.moveOffsetStreamController.add(event.localPosition);
                }
              },
              onPointerDown: (event) {
                pointer.pointerPosition = event.localPosition;
              },
              onPointerUp: (event) {
                _isFingerOnScreenSinceLongPress = false;
                pointer.upOffsetStreamController.add(event.localPosition);
              },
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class Pointer extends InheritedWidget {
  Pointer({super.key, required super.child});

  //This is a List<Offset> instead of just and Offset is so that it can be final
  //and still be mutable. Need to have this as final to keep Pointer immutable
  //which is recommended for inherited widgets.
  final _pointerPosition =
      List.generate(1, (_) => Offset.zero, growable: false);

  Offset get pointerPosition => _pointerPosition[0];

  set pointerPosition(Offset offset) {
    _pointerPosition[0] = offset;
  }

  final StreamController<Offset> onTapStreamController =
      StreamController.broadcast();

  final StreamController<Offset> onLongPressStreamController =
      StreamController.broadcast();

  final StreamController<Offset> moveOffsetStreamController =
      StreamController.broadcast();

  final StreamController<Offset> upOffsetStreamController =
      StreamController.broadcast();

  Future<dynamic> closeOnTapStreamController() {
    debugPrint("dragToSelect: Closing onTapStreamController");
    return onTapStreamController.close();
  }

  Future<dynamic> closeOnLongPressStreamController() {
    debugPrint("dragToSelect: Closing onLongPressStreamController");
    return onLongPressStreamController.close();
  }

  Future<dynamic> closeMoveOffsetController() {
    debugPrint("dragToSelect: Closing moveOffsetStreamController");
    return moveOffsetStreamController.close();
  }

  Future<dynamic> closeUpOffsetStreamController() {
    debugPrint("dragToSelect: Closing upOffsetStreamController");
    return upOffsetStreamController.close();
  }

  static Pointer? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Pointer>();
  }

  static Pointer of(BuildContext context) {
    final Pointer? result = maybeOf(context);
    assert(result != null, 'No Pointer found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(Pointer oldWidget) =>
      moveOffsetStreamController != oldWidget.moveOffsetStreamController ||
      upOffsetStreamController != oldWidget.upOffsetStreamController ||
      onTapStreamController != oldWidget.onTapStreamController ||
      onLongPressStreamController != oldWidget.onLongPressStreamController;
}
