import "dart:typed_data" show Float32List;

import "package:computer/computer.dart" show Computer;
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:logging/logging.dart" show Logger;
import "package:path/path.dart" show join;
import "package:path_provider/path_provider.dart"
    show getApplicationDocumentsDirectory;
import "package:photos/extensions/stop_watch.dart" show EnteWatch;
import "package:photos/src/rust/api/usearch_api.dart" as rust;
import "package:synchronized/synchronized.dart" show Lock;

enum VectorTable {
  faces,
  clip,
}

final _faceMlLock = Lock();
final _clipLock = Lock();

class VectorDB {
  final _logger = Logger("VectorDB");

  final _computer = Computer.shared();

  final Map<VectorTable, String> _tablePaths = {};

  // Singleton pattern
  VectorDB._privateConstructor();
  static final instance = VectorDB._privateConstructor();
  factory VectorDB() => instance;

  Future<String> getIndexPath(VectorTable table) async {
    _tablePaths[table] ??= await _initVectorDbTable(table);
    return _tablePaths[table]!;
  }

  Future<String> _initVectorDbTable(VectorTable table) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String tableDirectory =
        join(documentsDirectory.path, _vectorDbTablePath(table));
    return tableDirectory;
  }

  String _vectorDbTablePath(VectorTable table) {
    switch (table) {
      case VectorTable.faces:
        return "face_ml_index.usi";
      case VectorTable.clip:
        return "clip_index.usi";
    }
  }

  Lock _vectorDbLock(VectorTable table) {
    switch (table) {
      case VectorTable.faces:
        return _faceMlLock;
      case VectorTable.clip:
        return _clipLock;
    }
  }

  Future<(int, int, int)> getIndexStatus(
    VectorTable table,
  ) async {
    _logger.info("getIndexStatus called for $table");
    return await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('getIndexStatus for $table') : null)
        ?..start();
      final stats = await _computer.compute(
        _getIndexStatus,
        param: {
          "indexPath": getIndexPath(table),
        },
        taskName: "getIndexStatus in $table",
      ) as (int, int, int);
      w?.log('getIndexStatus for $table');
      return (stats.$1, stats.$2, stats.$3);
    });
  }

  static Future<(int, int, int, int, int)> _getIndexStatus(Map args) async {
    final String indexPath = args["indexPath"];
    final (size, capacity, dimensions, expansionAdd, expansionSearch) =
        await rust.getIndexStats(indexPath: indexPath);
    return (
      size.toInt(),
      capacity.toInt(),
      dimensions.toInt(),
      expansionAdd.toInt(),
      expansionSearch.toInt()
    );
  }

  Future<void> addVector(
    VectorTable table,
    int key,
    List<double> vector,
  ) async {
    _logger.info("addVector called for $table");
    await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('addVector for $table') : null)
        ?..start();
      await _computer.compute(
        _addVector,
        param: {
          "indexPath": getIndexPath(table),
          "key": key,
          "vector": vector,
        },
        taskName: "addVector in $table",
      );
      w?.log('addVector for $table');
    });
  }

  static Future<void> _addVector(Map args) async {
    final String indexPath = args["indexPath"];
    final BigInt key = BigInt.from(args["key"] as int);
    final List<double> vector = args["vector"];
    await rust.addVector(indexPath: indexPath, key: key, vector: vector);
  }

  Future<void> bulkAddVectors(
    VectorTable table,
    List<int> keys,
    List<List<double>> vectors,
  ) async {
    _logger.info("bulkAddVectors called for $table");
    await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('bulkAddVectors for $table') : null)
        ?..start();
      await _computer.compute(
        _bulkAddVectors,
        param: {
          "indexPath": getIndexPath(table),
          "vectors": vectors,
        },
        taskName: "bulkAddVectors in $table",
      );
      w?.log('bulkAddVectors in $table');
    });
  }

  static Future<void> _bulkAddVectors(Map args) async {
    final String indexPath = args["indexPath"];
    final List<List<double>> vectorsRaw = args["vectors"];
    final Uint64List keys = Uint64List.fromList(args["keys"] as List<int>);
    final List<Float32List> vectors =
        vectorsRaw.map((e) => Float32List.fromList(e)).toList();
    await rust.bulkAddVectors(
      indexPath: indexPath,
      keys: keys,
      vectors: vectors,
    );
  }

  Future<(Uint64List, Float32List)> searchVectors(
    VectorTable table,
    List<double> query,
    int count,
  ) async {
    _logger.info("searchVectors called for $table");
    return await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('searchVectors for $table') : null)
        ?..start();
      final (Uint64List, Float32List) results = await _computer.compute(
        _searchVectors,
        param: {
          "indexPath": getIndexPath(table),
          "query": query,
          "count": count,
        },
        taskName: "searchVectors in $table",
      );
      w?.log('searchVectors for $table');
      return results;
    });
  }

  static Future<(Uint64List, Float32List)> _searchVectors(Map args) async {
    final String indexPath = args["indexPath"];
    final List<double> query = args["query"];
    final BigInt count = BigInt.from(args["count"] as int);
    final (Uint64List keys, Float32List distances) = await rust.searchVectors(
      indexPath: indexPath,
      query: query,
      count: count,
    );
    return (keys, distances);
  }

  Future<int> removeVector(
    VectorTable table,
    int key,
  ) async {
    _logger.info("removeVector called for $table");
    return await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('removeVector for $table') : null)
        ?..start();
      final int removedCount = await _computer.compute(
        _removeVector,
        param: {
          "indexPath": getIndexPath(table),
          "key": key,
        },
        taskName: "removeVector in $table",
      );
      w?.log('removeVector for $table');
      return removedCount;
    });
  }

  static Future<int> _removeVector(Map args) async {
    final String indexPath = args["indexPath"];
    final BigInt key = BigInt.from(args["key"] as int);
    final removedCount =
        await rust.removeVector(indexPath: indexPath, key: key);
    assert(removedCount.isValidInt);
    return removedCount.toInt();
  }

  /// WARNING: This will remove all vectors from the index, use with caution.
  Future<void> resetIndex(
    VectorTable table,
  ) async {
    _logger.info("resetIndex called for $table");
    await _vectorDbLock(table).synchronized(() async {
      final w = (kDebugMode ? EnteWatch('resetIndex for $table') : null)
        ?..start();
      await _computer.compute(
        _resetIndex,
        param: {
          "indexPath": getIndexPath(table),
        },
        taskName: "resetIndex in $table",
      );
      w?.log('resetIndex for $table');
    });
  }

  static Future<void> _resetIndex(Map args) async {
    final String indexPath = args["indexPath"];
    await rust.resetIndex(indexPath: indexPath);
  }
}
