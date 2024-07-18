import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/component/group/lazy_group_gallery.dart";
import "package:photos/ui/viewer/gallery/component/multiple_groups_gallery_view.dart";

class SwipeToSelectHelper extends StatefulWidget {
  final List<EnteFile> files;
  final SelectedFiles selectedFiles;
  final Widget child;
  const SwipeToSelectHelper({
    required this.files,
    required this.selectedFiles,
    required this.child,
    super.key,
  });

  @override
  State<SwipeToSelectHelper> createState() => _SwipeToSelectHelperState();
}

class _SwipeToSelectHelperState extends State<SwipeToSelectHelper> {
  final _groupGalleryGlobalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LastSelectedFileByDragging(
      filesInGroup: widget.files,
      child: Builder(
        builder: (context) {
          return SelectionGesturesEventProvider(
            selectedFiles: widget.selectedFiles,
            files: widget.files,
            child: GroupGalleryGlobalKey(
              globalKey: _groupGalleryGlobalKey,
              child: SizedBox(
                key: _groupGalleryGlobalKey,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class LastSelectedFileByDragging extends InheritedWidget {
  ///Check if this should updates on didUpdateWidget. If so, use a state varaible
  ///and update it there on didUpdateWidget.
  final List<EnteFile> filesInGroup;
  LastSelectedFileByDragging({
    super.key,
    required this.filesInGroup,
    required super.child,
  });

  final _indexInGroup = ValueNotifier<int>(-1);

  void updateLastSelectedFile(EnteFile file) {
    _indexInGroup.value = filesInGroup.indexOf(file);
  }

  ValueNotifier<int> get index => _indexInGroup;

  static LastSelectedFileByDragging? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LastSelectedFileByDragging>();
  }

  static LastSelectedFileByDragging of(BuildContext context) {
    final LastSelectedFileByDragging? result = maybeOf(context);
    assert(result != null, 'No LastSelectedFileByDragging found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(LastSelectedFileByDragging oldWidget) =>
      _indexInGroup != oldWidget._indexInGroup ||
      filesInGroup != oldWidget.filesInGroup;
}

class SelectionGesturesEventProvider extends StatefulWidget {
  final Widget child;
  final List<EnteFile> files;
  final SelectedFiles selectedFiles;

  const SelectionGesturesEventProvider({
    super.key,
    required this.selectedFiles,
    required this.files,
    required this.child,
  });

  @override
  State<SelectionGesturesEventProvider> createState() =>
      _SelectionGesturesEventProviderState();
}

class _SelectionGesturesEventProviderState
    extends State<SelectionGesturesEventProvider> {
  late SelectionGesturesEvent selectionGesturesEvent;
  late SwipeToSelectGalleryScroll swipeToSelectGalleryScroll;
  bool _isFingerOnScreenSinceLongPress = false;
  bool _isDragging = false;
  int prevSelectedFileIndex = -1;
  int currentSelectedFileIndex = -1;
  final _logger = Logger("PointerProvider");
  static const kUpThreshold = 180.0;
  static const kDownThreshold = 240.0;
  static const kSelectionSheetBuffer = 120.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LastSelectedFileByDragging.of(context)
        .index
        .removeListener(swipingToSelectListener);
    LastSelectedFileByDragging.of(context)._indexInGroup.addListener(
          swipingToSelectListener,
        );
  }

  @override
  void dispose() {
    selectionGesturesEvent.closeMoveOffsetController();
    selectionGesturesEvent.closeUpOffsetStreamController();
    selectionGesturesEvent.closeOnTapStreamController();
    selectionGesturesEvent.closeOnLongPressStreamController();
    widget.selectedFiles.removeListener(
      swipingToSelectListener,
    );
    super.dispose();
  }

  void swipingToSelectListener() {
    prevSelectedFileIndex = currentSelectedFileIndex;
    currentSelectedFileIndex =
        LastSelectedFileByDragging.of(context).index.value;
    if (prevSelectedFileIndex != -1 && currentSelectedFileIndex != -1) {
      if ((currentSelectedFileIndex - prevSelectedFileIndex).abs() > 1) {
        late final int startIndex;
        late final int endIndex;
        if (currentSelectedFileIndex > prevSelectedFileIndex) {
          startIndex = prevSelectedFileIndex;
          endIndex = currentSelectedFileIndex;
        } else {
          startIndex = currentSelectedFileIndex;
          endIndex = prevSelectedFileIndex;
        }
        widget.selectedFiles.toggleFilesSelection(
          widget.files
              .sublist(
                startIndex + 1,
                endIndex,
              )
              .toSet(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final heightOfScreen = MediaQuery.sizeOf(context).height;

    return SelectionGesturesEvent(
      child: Builder(
        builder: (context) {
          selectionGesturesEvent = SelectionGesturesEvent.of(context);
          swipeToSelectGalleryScroll = SwipeToSelectGalleryScroll.of(context);
          return GestureDetector(
            onTap: () {
              selectionGesturesEvent.onTapStreamController
                  .add(selectionGesturesEvent.pointerPosition);
            },
            onLongPress: () {
              _isFingerOnScreenSinceLongPress = true;
              selectionGesturesEvent.onLongPressStreamController
                  .add(selectionGesturesEvent.pointerPosition);
            },
            onHorizontalDragUpdate: (details) {
              onDragToSelect(details.localPosition);
            },
            child: Listener(
              onPointerMove: (event) {
                selectionGesturesEvent.pointerPosition = event.localPosition;

                //onHorizontalDragUpdate is not called when dragging after
                //long press without lifting finger. This is for handling only
                //this case.
                if (_isFingerOnScreenSinceLongPress &&
                    (event.localDelta.dx.abs() > 0 &&
                        event.localDelta.dy.abs() > 0)) {
                  onDragToSelect(event.localPosition);

                  sinkScrollEvent(event.position.dy, heightOfScreen);
                }
              },
              onPointerDown: (event) {
                selectionGesturesEvent.pointerPosition = event.localPosition;
              },
              onPointerUp: (event) {
                _isFingerOnScreenSinceLongPress = false;
                _isDragging = false;
                selectionGesturesEvent.upOffsetStreamController
                    .add(event.localPosition);

                LastSelectedFileByDragging.of(context).index.value = -1;
                currentSelectedFileIndex = -1;
              },
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void onDragToSelect(Offset offset) {
    selectionGesturesEvent.moveOffsetStreamController.add(offset);
    _isDragging = true;
  }

  void sinkScrollEvent(double yGlobalPos, double heightOfScreen) {
    final pixelsBeyondThresholdDown =
        yGlobalPos - (heightOfScreen - kDownThreshold);
    final pixelsBeyondThresholdUp = yGlobalPos - kUpThreshold;

    if (pixelsBeyondThresholdUp < 0) {
      print(
        "up with strength: ${pixelsBeyondThresholdUp / kUpThreshold}",
      );
      swipeToSelectGalleryScroll.streamController.sink
          .add(pixelsBeyondThresholdUp / kUpThreshold);
    }
    if (pixelsBeyondThresholdDown > 0) {
      print(
        "down with strength: ${(pixelsBeyondThresholdDown + kSelectionSheetBuffer) / kDownThreshold}",
      );
      swipeToSelectGalleryScroll.streamController.sink.add(
        (pixelsBeyondThresholdDown + kSelectionSheetBuffer) / kDownThreshold,
      );
    }
  }
}

class SelectionGesturesEvent extends InheritedWidget {
  SelectionGesturesEvent({super.key, required super.child});

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

  static SelectionGesturesEvent? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SelectionGesturesEvent>();
  }

  static SelectionGesturesEvent of(BuildContext context) {
    final SelectionGesturesEvent? result = maybeOf(context);
    assert(result != null, 'No SelectionGesturesEvent found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(SelectionGesturesEvent oldWidget) =>
      moveOffsetStreamController != oldWidget.moveOffsetStreamController ||
      upOffsetStreamController != oldWidget.upOffsetStreamController ||
      onTapStreamController != oldWidget.onTapStreamController ||
      onLongPressStreamController != oldWidget.onLongPressStreamController;
}
