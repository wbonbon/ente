import "package:flutter/foundation.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/filter_updated_event.dart";
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

  static FiltersContextState get instance => _instance;

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

  List<EnteFile> filterFiles(String s, List<EnteFile> dbFiles) {
    final activeFilters = getActiveFilters(s);
    if (activeFilters.filters.isEmpty) {
      return dbFiles;
    }
    final result = <EnteFile>[];
    for (final file in dbFiles) {
      bool shouldAdd = true;
      for (final filter in activeFilters.filters) {
        if (!filter.filter(file)) {
          shouldAdd = false;
          break;
        }
      }
      if (shouldAdd) {
        result.add(file);
      }
    }
    return result;
  }

  void notifyFilterUpdated(String contextKey) {
    Bus.instance.fire(FilterUpdatedEvent(contextKey));
  }
}
