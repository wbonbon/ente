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
    Pointer.of(context).closePositionController();
    Pointer.of(context).closeDownEventController();
    Pointer.of(context).upDownEventController();
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
                    .positionStreamController
                    .add(event.localPosition);
              }
            },
            onPointerDown: (event) {
              Pointer.of(context)
                  .downEventStreamController
                  .add(event.localPosition);
            },
            onPointerUp: (event) {
              Pointer.of(context)
                  .upEventStreamController
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

  final StreamController<Offset> positionStreamController =
      StreamController.broadcast();

  final StreamController<Offset> downEventStreamController =
      StreamController.broadcast();

  final StreamController<Offset> upEventStreamController =
      StreamController.broadcast();

  Future<dynamic> closePositionController() {
    debugPrint("dragToSelect: Closing position stream controller");
    return positionStreamController.close();
  }

  Future<dynamic> closeDownEventController() {
    debugPrint("dragToSelect: Closing down event stream controller");
    return downEventStreamController.close();
  }

  Future<dynamic> upDownEventController() {
    debugPrint("dragToSelect: Closing up event stream controller");
    return upEventStreamController.close();
  }

  static Pointer? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Pointer>();
  }

  static Pointer of(BuildContext context) {
    final Pointer? result = maybeOf(context);
    assert(result != null, 'No PointerPositionProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(Pointer oldWidget) =>
      positionStreamController != oldWidget.positionStreamController ||
      downEventStreamController != oldWidget.downEventStreamController ||
      upEventStreamController != oldWidget.upEventStreamController;
}
