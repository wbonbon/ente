import "package:flutter/material.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";

class GalleryContextState extends InheritedWidget {
  ///Sorting by creation time
  final bool sortOrderAsc;
  final bool inSelectionMode;
  final GroupType type;
  final ScrollController scrollController;

  const GalleryContextState({
    this.inSelectionMode = false,
    this.type = GroupType.day,
    required this.sortOrderAsc,
    required this.scrollController,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

//TODO: throw error with message if no GalleryContextState found
  static GalleryContextState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GalleryContextState>();
  }

  @override
  bool updateShouldNotify(GalleryContextState oldWidget) {
    return sortOrderAsc != oldWidget.sortOrderAsc ||
        inSelectionMode != oldWidget.inSelectionMode ||
        type != oldWidget.type;
  }
}
