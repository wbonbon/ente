import 'dart:math';

import "package:logging/logging.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:shared_preferences/shared_preferences.dart";

const _promptsJson = {
  "prompts": [
    {
      "prompt": "identity document",
      "title": "Identity Document",
      "minimumScore": 0.269,
      "minimumSize": 0.0,
    },
    {
      "prompt": "sunset at the beach",
      "title": "Sunset",
      "minimumScore": 0.25,
      "minimumSize": 0.0,
    },
    {
      "prompt": "roadtrip",
      "title": "Roadtrip",
      "minimumScore": 0.26,
      "minimumSize": 0.0,
    },
    {
      "prompt": "pizza pasta burger",
      "title": "Food",
      "minimumScore": 0.27,
      "minimumSize": 0.0,
    }
  ],
};

class MagicCacheService {
  static const _key = "magic";
  late SharedPreferences prefs;
  final Logger _logger = Logger((MagicCacheService).toString());
  MagicCacheService._privateConstructor();

  static final MagicCacheService instance =
      MagicCacheService._privateConstructor();

  void init(SharedPreferences preferences) {
    prefs = preferences;
  }

  List<Map<String, Object>> getRandomPrompts() {
    final promptsJson = _promptsJson["prompts"];
    final randomPrompts = <Map<String, Object>>[];
    final randomNumbers =
        _generateUniqueRandomNumbers(promptsJson!.length - 1, 4);
    for (int i = 0; i < randomNumbers.length; i++) {
      randomPrompts.add(promptsJson[randomNumbers[i]]);
    }

    return randomPrompts;
  }

  Future<List<int>> getMatchingFileIDsForPromptData(
    Map<String, Object> promptData,
  ) {
    return SemanticSearchService.instance.getMatchingFileIDs(
      promptData["prompt"] as String,
      promptData["minimumScore"] as double,
    );
  }

  ///Generates from 0 to max unique random numbers
  List<int> _generateUniqueRandomNumbers(int max, int count) {
    final numbers = <int>[];
    for (int i = 1; i <= count;) {
      final randomNumber = Random().nextInt(max + 1);
      if (numbers.contains(randomNumber)) {
        continue;
      }
      numbers.add(randomNumber);
      i++;
    }
    return numbers;
  }
}
