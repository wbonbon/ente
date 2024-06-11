import "package:flutter/foundation.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/services/filter/filter.dart";

class ActiveFilters {
  List<EnteFile> allFiles = [];
  List<Filter> filters = [];
}

class FiltersContextState {
  Map<String, ActiveFilters> keyToActiveFiles = {};
  // static instance
  static final FiltersContextState _instance = FiltersContextState();

  factory FiltersContextState() {
    return _instance;
  }

  void registerContext(String contextKey) {
    if (keyToActiveFiles.containsKey(contextKey)) {
      debugPrint("Context already registered: $contextKey");
    }
    keyToActiveFiles[contextKey] = ActiveFilters();
  }

  void unregisterContext(String contextKey) {
    if (!keyToActiveFiles.containsKey(contextKey)) {
      debugPrint("Context not registered: $contextKey");
    }
    keyToActiveFiles.remove(contextKey);
  }

  bool hasActiveFilters(String contextKey) {
    return keyToActiveFiles[contextKey]!.filters.isNotEmpty;
  }

  ActiveFilters getActiveFilters(String contextKey) {
    return keyToActiveFiles[contextKey]!;
  }

  String buildKey(GalleryType galleryType, {int? collectionID}) {
    late String key;
    if (galleryType == GalleryType.sharedCollection ||
        galleryType == GalleryType.hiddenOwnedCollection ||
        galleryType == GalleryType.ownedCollection) {
      key = "${galleryType.name}_collection_$collectionID";
    } else {
      key = galleryType.name;
    }
    return key;
  }
}
