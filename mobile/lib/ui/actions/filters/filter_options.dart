import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filter/filter.dart";
import "package:photos/services/filter/type_filter.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/state/filters_context_state.dart";

class FilterOptionsWidget extends StatefulWidget {
  final String contextKey;

  const FilterOptionsWidget(this.contextKey, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterOptionsWidgetState();
  }
}

class _FilterOptionsWidgetState extends State<FilterOptionsWidget> {
  final Logger _logger = Logger("_FilterOptionsWidgetState");
  bool hasInitOnce = false;
  final Map<FileType, bool> fileTypes = {
    FileType.video: false,
    FileType.image: false,
    FileType.livePhoto: false,
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ActiveFilters activeFilters =
        filtersContextState.getActiveFilters(widget.contextKey);
    if (hasInitOnce == false) {
      for (final filter in activeFilters.filters ?? []) {
        if (filter is TypeFilter) {
          fileTypes[filter.type] = true;
        }
      }
      hasInitOnce = true;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ChipButtonWidget(
                  "Video",
                  boxColor: fileTypes[FileType.video]!
                      ? getEnteColorScheme(context).primary700
                      : null,
                  onTap: () {
                    setState(() {
                      fileTypes[FileType.video] = !fileTypes[FileType.video]!;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ChipButtonWidget(
                  "Image",
                  boxColor: fileTypes[FileType.image]!
                      ? getEnteColorScheme(context).primary700
                      : null,
                  onTap: () {
                    setState(() {
                      fileTypes[FileType.image] = !fileTypes[FileType.image]!;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ChipButtonWidget(
                  "Live Photo",
                  boxColor: fileTypes[FileType.livePhoto]!
                      ? getEnteColorScheme(context).primary700
                      : null,
                  onTap: () {
                    setState(() {
                      fileTypes[FileType.livePhoto] =
                          !fileTypes[FileType.livePhoto]!;
                    });
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ButtonWidget(
              buttonType: ButtonType.primary,
              labelText: "Apply",
              buttonAction: ButtonAction.first,
              onTap: () async {
                try {
                  final List<Filter> newFilters = [];
                  for (final fileType in fileTypes.keys) {
                    if (fileTypes[fileType]!) {
                      newFilters.add(TypeFilter(fileType));
                    }
                  }
                  activeFilters.filters.clear();
                  activeFilters.filters.addAll(newFilters);
                  filtersContextState.notifyFilterUpdated(widget.contextKey);
                  Navigator.of(context).pop();
                } catch (e) {
                  _logger.warning("Error while popping filter sheet $e");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showFilterSheet(
  BuildContext bcontext,
  final String contextKey,
) async {
  final colorScheme = getEnteColorScheme(bcontext);
  return showBarModalBottomSheet(
    expand: false,
    topControl: const SizedBox.shrink(),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    backgroundColor: colorScheme.backgroundElevated,
    barrierColor: backdropFaintDark,
    context: bcontext,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FilterOptionsWidget(contextKey),
      );
    },
  );
}
