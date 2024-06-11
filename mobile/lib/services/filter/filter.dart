import 'package:photos/models/file/file.dart';

abstract class Filter {
  // True value indicates that the file passes the filter, and we should keep it
  bool filter(EnteFile file);
}
