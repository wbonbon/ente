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
  @override
  void dispose() {
    Pointer.of(context).closeMoveOffsetController();
    Pointer.of(context).closeDownOffsetStreamController();
    Pointer.of(context).closeUpOffsetStreamController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pointer(
      child: Builder(
        builder: (context) {
          return Listener(
            onPointerMove: (event) {
              if (event.delta.distance > 0) {
                Pointer.of(context)
                    .moveOffsetStreamController
                    .add(event.localPosition);
              }
            },
            onPointerDown: (event) {
              Pointer.of(context)
                  .downOffsetStreamController
                  .add(event.localPosition);
            },
            onPointerUp: (event) {
              Pointer.of(context)
                  .upOffsetStreamController
                  .add(event.localPosition);
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

  final StreamController<Offset> downOffsetStreamController =
      StreamController.broadcast();

  final StreamController<Offset> upOffsetStreamController =
      StreamController.broadcast();

  Future<dynamic> closeMoveOffsetController() {
    debugPrint("dragToSelect: Closing moveOffsetStreamController");
    return moveOffsetStreamController.close();
  }

  Future<dynamic> closeDownOffsetStreamController() {
    debugPrint("dragToSelect: Closing downOffsetStreamController");
    return downOffsetStreamController.close();
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
      downOffsetStreamController != oldWidget.downOffsetStreamController ||
      upOffsetStreamController != oldWidget.upOffsetStreamController;
}
