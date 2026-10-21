import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/local_cropcare_assistant_service.dart';

void main() {
  const assistant = LocalCropCareAssistantService();

  group('LocalCropCareAssistantService', () {
    test('retrieves tomato early blight symptoms from the local guide', () {
      final answer = assistant.answerQuestion(
        'What are tomato early blight symptoms?',
      );

      expect(answer, contains('Tomato Early Blight (Tomato)'));
      expect(answer, contains('concentric rings'));
      expect(answer, contains('not a confirmed diagnosis'));
      expect(answer, isNot(contains('Potato Early Blight')));
    });

    test('returns relevant management guidance for a crop and disease', () {
      final answer = assistant.answerQuestion(
        'How do I manage potato late blight?',
      );

      expect(answer, contains('Potato Late Blight (Potato)'));
      expect(answer, contains('cool, wet weather'));
      expect(answer, contains('product labels'));
    });

    test(
      'uses scan context for follow-up questions without a disease name',
      () {
        final answer = assistant.answerQuestion(
          'What should I do?',
          prediction: 'Tomato___Early_blight',
        );

        expect(answer, contains('last scan suggested'));
        expect(answer, contains('Tomato Early Blight'));
        expect(answer, contains('Water at the plant base'));
      },
    );

    test('uses scan context for short referential follow-up questions', () {
      final answer = assistant.answerQuestion(
        'Tell me more about it',
        prediction: 'Tomato___Early_blight',
      );

      expect(answer, contains('last scan suggested'));
      expect(answer, contains('Tomato Early Blight'));
    });

    test('lists supported conditions for a crop', () {
      final answer = assistant.answerQuestion(
        'What are common tomato diseases?',
      );

      expect(answer, contains('Tomato Yellow Leaf Curl Virus'));
      expect(answer, contains('Tomato Early Blight'));
      expect(answer, contains('not a complete list'));
    });

    test('answers general prevention questions from library guidance', () {
      final answer = assistant.answerQuestion(
        'How can I prevent crop diseases?',
      );

      expect(answer, contains('offline guide'));
      expect(answer, contains('regular monitoring'));
      expect(answer, contains('residue-borne inoculum'));
    });

    test('does not invent information for unsupported crops', () {
      final answer = assistant.answerQuestion('How do I treat wheat rust?');

      expect(answer, contains('does not include that crop'));
      expect(
        answer,
        contains('currently covers apple, corn, grape, potato, and tomato'),
      );
    });

    test('handles empty input and greetings locally', () {
      expect(
        assistant.answerQuestion('  '),
        contains('supported crop, disease, symptom'),
      );
      expect(
        assistant.answerQuestion('Hello!'),
        contains('offline CropCare guide'),
      );
    });
  });
}
