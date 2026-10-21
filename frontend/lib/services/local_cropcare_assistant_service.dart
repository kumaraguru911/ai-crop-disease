import '../models/disease_information.dart';
import 'disease_information_service.dart';

class LocalCropCareAssistantService {
  const LocalCropCareAssistantService();

  static const Set<String> _stopWords = {
    'a',
    'about',
    'and',
    'are',
    'can',
    'do',
    'for',
    'give',
    'how',
    'i',
    'in',
    'is',
    'it',
    'me',
    'of',
    'on',
    'please',
    'show',
    'tell',
    'the',
    'to',
    'what',
    'with',
    'you',
  };

  static final RegExp _preventionIntent = RegExp(
    r'\b(prevent|prevention|avoid|protect|reduce risk)\b',
  );
  static final RegExp _managementIntent = RegExp(
    r'\b(treat|treatment|manage|management|control|cure|fix|stop|recommend|should|advice|next step)\b',
  );
  static final RegExp _symptomIntent = RegExp(
    r'\b(symptom|symptoms|sign|signs|look like|appear)\b',
  );
  static final RegExp _conditionIntent = RegExp(
    r'\b(disease|diseases|condition|conditions|common|list)\b',
  );
  static final RegExp _greetingIntent = RegExp(
    r'^(hi|hello|hey|good morning|good afternoon|good evening)\b',
  );

  static const Map<String, List<String>> _cropAliases = {
    'Apple': ['apple', 'apples'],
    'Corn': ['corn', 'maize'],
    'Grape': ['grape', 'grapes', 'grapevine'],
    'Potato': ['potato', 'potatoes'],
    'Tomato': ['tomato', 'tomatoes'],
  };

  static const List<String> _unsupportedCropAliases = [
    'banana',
    'citrus',
    'cotton',
    'cucumber',
    'mango',
    'onion',
    'orange',
    'pepper',
    'rice',
    'soy',
    'soybean',
    'strawberry',
    'wheat',
  ];

  String answerQuestion(String question, {String? prediction}) {
    final normalizedQuery = _normalize(question);

    if (normalizedQuery.isEmpty) {
      return 'Ask me about a supported crop, disease, symptom, or care topic.';
    }

    if (_greetingIntent.hasMatch(normalizedQuery)) {
      return 'Hello! I can look up symptoms and management guidance for '
          'apple, corn, grape, potato, and tomato in the offline CropCare guide.';
    }

    final crops = _mentionedCrops(normalizedQuery);
    final diseases = DiseaseInformationService.all;
    if (_unsupportedCropAliases.any(
      (crop) =>
          RegExp('\\b${RegExp.escape(crop)}\\b').hasMatch(normalizedQuery),
    )) {
      return _unsupportedTopicAnswer();
    }

    final asksForConditionList = _conditionIntent.hasMatch(normalizedQuery);
    final queryTerms = _terms(normalizedQuery);
    final hasSpecificDiseaseTerms = diseases.any(
      (disease) => _diseaseTerms(disease).intersection(queryTerms).isNotEmpty,
    );
    DiseaseInformation? scanDisease;
    for (final disease in diseases) {
      if (disease.className == prediction) {
        scanDisease = disease;
        break;
      }
    }

    if (scanDisease != null &&
        !hasSpecificDiseaseTerms &&
        (crops.isEmpty || crops.contains(scanDisease.crop)) &&
        !_preventionIntent.hasMatch(normalizedQuery) &&
        (_symptomIntent.hasMatch(normalizedQuery) ||
            _managementIntent.hasMatch(normalizedQuery) ||
            RegExp(r'\b(it|this|that|result)\b').hasMatch(normalizedQuery))) {
      final details = _symptomIntent.hasMatch(normalizedQuery)
          ? _symptomAnswer([scanDisease])
          : _managementAnswer([scanDisease]);
      return 'The last scan suggested **${scanDisease.diseaseName} '
          '(${scanDisease.crop})**, but it may be wrong. If that result is '
          'correct:\n\n$details';
    }

    if (asksForConditionList && crops.length == 1 && !hasSpecificDiseaseTerms) {
      return _conditionList(crops.single);
    }

    if (_preventionIntent.hasMatch(normalizedQuery) &&
        !hasSpecificDiseaseTerms) {
      return _generalPreventionAdvice(crops);
    }

    final matches = _rankDiseases(normalizedQuery, diseases, crops);

    if (matches.isEmpty) {
      return 'I could not find a matching topic in the offline CropCare guide. '
          'Try naming apple, corn, grape, potato, or tomato and a supported '
          'condition such as early blight or rust.';
    }

    if (_symptomIntent.hasMatch(normalizedQuery)) {
      return _symptomAnswer(matches);
    }

    if (_managementIntent.hasMatch(normalizedQuery) ||
        _preventionIntent.hasMatch(normalizedQuery)) {
      return _managementAnswer(matches);
    }

    return _aboutAnswer(matches);
  }

  List<DiseaseInformation> _rankDiseases(
    String query,
    List<DiseaseInformation> diseases,
    List<String> crops,
  ) {
    final queryTerms = _terms(query)
        .where((term) => term.length > 2 && !_stopWords.contains(term))
        .toSet();
    final ranked = <({DiseaseInformation disease, int score})>[];

    for (final disease in diseases) {
      if (crops.isNotEmpty && !crops.contains(disease.crop)) {
        continue;
      }

      final nameTerms = _terms('${disease.diseaseName} ${disease.className}');
      final symptomTerms = _terms(
        '${disease.description} ${disease.symptoms.join(' ')}',
      );
      final managementTerms = _terms(disease.treatment.join(' '));
      var score = 0;

      for (final term in queryTerms) {
        if (nameTerms.contains(term)) {
          score += 5;
        } else if (symptomTerms.contains(term)) {
          score += 2;
        } else if (managementTerms.contains(term)) {
          score += 1;
        }
      }

      final normalizedName = _normalize(disease.diseaseName);
      if (normalizedName.length > 4 && query.contains(normalizedName)) {
        score += 12;
      }

      if (crops.contains(disease.crop)) {
        score += 8;
      }

      if (score > 0) {
        ranked.add((disease: disease, score: score));
      }
    }

    ranked.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      if (scoreOrder != 0) {
        return scoreOrder;
      }
      return left.disease.diseaseName.compareTo(right.disease.diseaseName);
    });

    return ranked.take(3).map((match) => match.disease).toList();
  }

  List<String> _mentionedCrops(String query) {
    return _cropAliases.entries
        .where(
          (entry) => entry.value.any(
            (alias) => RegExp('\\b${RegExp.escape(alias)}\\b').hasMatch(query),
          ),
        )
        .map((entry) => entry.key)
        .toList();
  }

  Set<String> _diseaseTerms(DiseaseInformation disease) {
    final cropTerms = _cropAliases.values.expand((aliases) => aliases).toSet();
    return _terms('${disease.diseaseName} ${disease.className}')
      ..removeAll(cropTerms)
      ..removeAll({
        'common',
        'condition',
        'conditions',
        'disease',
        'diseases',
        'healthy',
        'symptom',
        'symptoms',
      })
      ..removeWhere((term) => term.length < 4);
  }

  String _unsupportedTopicAnswer() {
    return 'The offline guide does not include that crop. It currently covers '
        'apple, corn, grape, potato, and tomato.';
  }

  String _conditionList(String crop) {
    final conditions = DiseaseInformationService.all
        .where((disease) => disease.crop == crop && !disease.isHealthy)
        .map((disease) => disease.diseaseName)
        .toList();

    return 'The offline guide includes these $crop conditions:\n'
        '${conditions.map((condition) => '- $condition').join('\n')}'
        '\n\nThe classifier only covers its listed classes; this is not a '
        'complete list of conditions for the crop.';
  }

  String _generalPreventionAdvice(List<String> crops) {
    final entries = DiseaseInformationService.all.where(
      (disease) => crops.isEmpty || crops.contains(disease.crop),
    );
    final treatments = entries.expand((disease) => disease.treatment);
    final suggestions = <String>[];

    const categories = <List<String>>[
      ['crop debris', 'infected plant material', 'plant debris', 'sanitation'],
      ['monitor', 'scout', 'inspect', 'regularly'],
      ['airflow', 'air circulation', 'leaf wetness', 'keep foliage dry'],
      ['rotate', 'crop rotation'],
      ['healthy planting', 'healthy seed', 'disease-free', 'resistant'],
    ];

    for (final category in categories) {
      final candidates = treatments.where((treatment) {
        final normalizedTreatment = treatment.toLowerCase();
        return category.any(normalizedTreatment.contains);
      }).toList();
      candidates.sort(
        (left, right) =>
            _genericityScore(right).compareTo(_genericityScore(left)),
      );

      for (final treatment in candidates) {
        if (!suggestions.contains(treatment)) {
          suggestions.add(treatment);
          break;
        }
      }
    }

    if (suggestions.isEmpty) {
      return 'The offline guide has no general prevention advice for that '
          'request. Try asking about a supported crop or a specific condition.';
    }

    final scope = crops.isEmpty ? 'crop-care' : crops.single.toLowerCase();
    return 'The offline guide suggests these general $scope prevention steps:\n'
        '${suggestions.map((suggestion) => '- $suggestion').join('\n')}';
  }

  int _genericityScore(String guidance) {
    final normalized = guidance.toLowerCase();
    var score = 0;

    if (normalized.contains('regular')) score += 2;
    if (normalized.contains('crop')) score += 2;
    if (normalized.contains('plant material')) score += 2;
    if (RegExp(r'\b(apple|corn|grape|potato|tomato|juniper|orchard)\b')
        .hasMatch(normalized)) {
      score -= 4;
    }

    return score;
  }

  String _symptomAnswer(List<DiseaseInformation> matches) {
    final sections = matches.map((disease) {
      if (disease.symptoms.isEmpty) {
        return '**${disease.diseaseName} (${disease.crop})** is the healthy '
            'class in the guide and has no listed disease symptoms.';
      }

      return '**${disease.diseaseName} (${disease.crop})**\n'
          '${disease.symptoms.take(4).map((symptom) => '- $symptom').join('\n')}';
    });

    return 'Symptoms listed in the offline guide:\n\n${sections.join('\n\n')}'
        '\n\nSimilar symptoms can have different causes; this is not a confirmed diagnosis.';
  }

  String _managementAnswer(List<DiseaseInformation> matches) {
    final sections = matches.map((disease) {
      return '**${disease.diseaseName} (${disease.crop})**\n'
          '${disease.treatment.take(4).map((tip) => '- $tip').join('\n')}';
    });

    return 'Care guidance from the offline guide:\n\n${sections.join('\n\n')}'
        '\n\nFollow local agricultural advice and product labels.';
  }

  String _aboutAnswer(List<DiseaseInformation> matches) {
    final sections = matches.map(
      (disease) =>
          '**${disease.diseaseName} (${disease.crop})**\n${disease.description}',
    );

    return 'Here is what the offline guide says:\n\n${sections.join('\n\n')}'
        '\n\nAsk about symptoms or management for more detail.';
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _terms(String text) => _normalize(text).split(' ').toSet();
}
