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

  @override
  void dispose() {
    pointer.closeMoveOffsetController();
    pointer.closeUpOffsetStreamController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pointer(
      child: Builder(
        builder: (context) {
          pointer = Pointer.of(context);
          return Listener(
            onPointerMove: (event) {
              if (event.delta.distance > 0) {
                pointer.moveOffsetStreamController.add(event.localPosition);
              }
            },
            onPointerUp: (event) {
              pointer.upOffsetStreamController.add(event.localPosition);
            },
            child: widget.child,
          );
        },
      ),
    );
  }
}

class Pointer extends InheritedWidget {
  Pointer({super.key, required super.child});

  final StreamController<Offset> moveOffsetStreamController =
      StreamController.broadcast();

  final StreamController<Offset> upOffsetStreamController =
      StreamController.broadcast();

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
      upOffsetStreamController != oldWidget.upOffsetStreamController;
}
