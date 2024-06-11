import 'package:photos/events/event.dart';

class FilterUpdatedEvent extends Event {
  final String contextKey;

  FilterUpdatedEvent(
    this.contextKey,
  );
}
