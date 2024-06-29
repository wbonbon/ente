import "dart:async";

import "package:flutter/widgets.dart";

class PointerPositionProvider extends StatefulWidget {
  final Widget child;
  const PointerPositionProvider({
    super.key,
    required this.child,
  });

  @override
  State<PointerPositionProvider> createState() =>
      _PointerPositionProviderState();
}

class _PointerPositionProviderState extends State<PointerPositionProvider> {
  @override
  void dispose() {
    PointerPosition.of(context).pointerPositionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PointerPosition(
      child: Builder(
        builder: (context) {
          return Listener(
            onPointerMove: (PointerMoveEvent event) {
              PointerPosition.of(context)
                  .pointerPositionStreamController
                  .add(event.localPosition);
            },
            child: widget.child,
          );
        },
      ),
    );
  }
}

class PointerPosition extends InheritedWidget {
  PointerPosition({super.key, required super.child});

  final StreamController<Offset> pointerPositionStreamController =
      StreamController.broadcast();

  Future<dynamic> closeController() {
    debugPrint("dragToSelect: Closing stream controller");
    return pointerPositionStreamController.close();
  }

  static PointerPosition? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PointerPosition>();
  }

  static PointerPosition of(BuildContext context) {
    final PointerPosition? result = maybeOf(context);
    assert(result != null, 'No PointerPositionProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(PointerPosition oldWidget) =>
      pointerPositionStreamController !=
      oldWidget.pointerPositionStreamController;
}
