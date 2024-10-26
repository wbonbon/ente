import "package:collection/collection.dart";
import 'package:ml_linalg/vector.dart';

class Data {
  final Vector vector;
  final String id;

  // subPar is used to indicate that the data point is not perfect.
  // During scoring comparison, we use this information to adjust the similarity threshold
  final bool subPar;

  Data(this.vector, this.id, {this.subPar = false});
}

class QueryResult {
  final Data data;

  // dot product (cosine similarity since vectors are normalized)
  final double similarity;

  QueryResult(this.data, this.similarity);
}

// Create a nullable type for method that will take Data as input and return true/false
typedef DataPredicate = bool Function(Data);

class LSH {
  final List<Vector> hyperplanes;
  final int dimensions;
  final int numHashTables;
  final int bitsPerTable;
  final List<Map<String, List<Data>>> hashTables;
  final double similarityThreshold; // minimum similarity threshold
  final double subParPenalty;

  LSH(
    this.numHashTables,
    this.dimensions, {
    this.bitsPerTable = 4,
    this.similarityThreshold = 0.76,
    this.subParPenalty = 0.08,
  })  : hyperplanes = List.generate(
          numHashTables * bitsPerTable,
          (_) => Vector.randomFilled(dimensions, min: -1, max: 1),
        ),
        hashTables = List.generate(numHashTables, (_) => {});

  void addVector(Data data) {
    final List<int> hashes = hashVector(data.vector);
    for (int i = 0; i < numHashTables; i++) {
      final String hashKey = _getHashKey(hashes, i);
      final bucket = hashTables[i].putIfAbsent(hashKey, () => []);
      bucket.add(data);
    }
  }

  List<int> hashVector(Vector vector) {
    return List.generate(hyperplanes.length, (i) {
      final double dotProduct = vector.dot(hyperplanes[i]);
      return ((dotProduct + 1) * 8).floor().clamp(0, 8);
    });
  }

  String _getHashKey(List<int> hashes, int tableIndex) {
    final int start = tableIndex * bitsPerTable;
    return hashes.sublist(start, start + bitsPerTable).join('_');
  }

  List<QueryResult> query(
    Data queryData,
    int n, {
    DataPredicate? filter,
  }) {
    final Set<Data> candidates = {};
    final List<int> hashes = hashVector(queryData.vector);

    // First pass: exact bucket matches
    for (int i = 0; i < numHashTables; i++) {
      final String hashKey = _getHashKey(hashes, i);
      if (hashTables[i].containsKey(hashKey)) {
        candidates.addAll(hashTables[i][hashKey]!);
      }
    }
    if (filter != null) {
      candidates.removeWhere((data) => !filter(data));
    }

    // Second pass: check neighboring buckets if needed
    if (candidates.length < n * 2) {
      for (int i = 0; i < numHashTables; i++) {
        final String hashKey = _getHashKey(hashes, i);
        _addNeighboringBuckets(hashKey, hashTables[i], candidates);
      }
    }
    if (filter != null) {
      candidates.removeWhere((data) => !filter(data));
    }

    return _getTopNWithSimilarity(queryData, candidates.toList(), n);
  }

  void _addNeighboringBuckets(
    String hashKey,
    Map<String, List<Data>> table,
    Set<Data> candidates,
  ) {
    final List<int> bits = hashKey.split('_').map(int.parse).toList();
    for (int i = 0; i < bits.length; i++) {
      bits[i] = (bits[i] + 1) % 16; // Try neighboring value
      final String neighborKey = bits.join('_');
      if (table.containsKey(neighborKey)) {
        candidates.addAll(table[neighborKey]!);
      }
      bits[i] = (bits[i] - 1) % 16; // Restore original
    }
  }

  List<QueryResult> _getTopNWithSimilarity(
    Data inputQuery,
    List<Data> candidates,
    int n,
  ) {
    final PriorityQueue<QueryResult> pq = PriorityQueue<QueryResult>(
      (a, b) => a.similarity.compareTo(b.similarity),
    );
    final Set<String> alreadySeen = {};
    // Iterate through all candidates and compute similarity
    for (var data in candidates) {
      if (alreadySeen.contains(data.id) || data.id == inputQuery.id) {
        continue;
      }
      alreadySeen.add(data.id);
      late final double threshold;
      if (data.subPar || inputQuery.subPar) {
        threshold = similarityThreshold + subParPenalty;
      } else {
        threshold = similarityThreshold;
      }
      final double similarity = data.vector.dot(inputQuery.vector);
      if (similarity >= threshold) {
        final result = QueryResult(data, similarity);
        if (pq.length < n) {
          pq.add(result);
        } else if (similarity > pq.first.similarity) {
          pq.removeFirst();
          pq.add(result);
        }
      }
    }
    // Convert the priority queue into a sorted list (descending order)
    final List<QueryResult> topNResults = pq.toList()
      ..sort((a, b) => b.similarity.compareTo(a.similarity));

    return topNResults;
  }
}
