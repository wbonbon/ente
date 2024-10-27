class FileSimilarityAnalyzer {
  final Map<int, Map<int, double>> _adjacencyMap = {};

  FileSimilarityAnalyzer(List<(int, int, double)> pairs) {
    for (var pair in pairs) {
      final int file1 = pair.$1;
      final int file2 = pair.$2;
      final double score = pair.$3;
      // Add both directions since the relationship is symmetric
      _adjacencyMap.putIfAbsent(file1, () => {});
      _adjacencyMap.putIfAbsent(file2, () => {});
      _adjacencyMap[file1]![file2] = score;
      _adjacencyMap[file2]![file1] = score;
    }
  }

  // Find all neighboring files that meet the threshold
  Set<int> findNeighbors(int fileId, double threshold) {
    if (!_adjacencyMap.containsKey(fileId)) {
      return {};
    }

    return _adjacencyMap[fileId]!
        .entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toSet();
  }

  // Find all groups of similar files using DFS
  List<Set<int>> findDuplicateFiles(double threshold) {
    final Set<int> visited = {};
    final List<Set<int>> groups = [];

    void dfs(int fileId, Set<int> currentGroup) {
      visited.add(fileId);
      currentGroup.add(fileId);

      for (var entry in _adjacencyMap[fileId]!.entries) {
        if (!visited.contains(entry.key) && entry.value >= threshold) {
          dfs(entry.key, currentGroup);
        }
      }
    }

    // Start DFS from each unvisited file
    for (var fileId in _adjacencyMap.keys) {
      if (!visited.contains(fileId)) {
        final Set<int> currentGroup = {};
        dfs(fileId, currentGroup);
        // Only add groups with more than one file
        if (currentGroup.length > 1) {
          groups.add(currentGroup);
        }
      }
    }

    return groups;
  }
}
