import 'dart:io';

import 'package:flutter/material.dart';

import '../models/disease_information.dart';
import '../services/crop_disease_inference_service.dart';
import 'chatbot_screen.dart';

class DiseaseResultScreen extends StatelessWidget {
  String _getClassId() {
    const classIds = [
      'Apple___Apple_scab',
      'Apple___Black_rot',
      'Apple___Cedar_apple_rust',
      'Apple___healthy',
      'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
      'Corn_(maize)___Common_rust_',
      'Corn_(maize)___Northern_Leaf_Blight',
      'Corn_(maize)___healthy',
      'Grape___Black_rot',
      'Grape___Esca_(Black_Measles)',
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
      'Grape___healthy',
      'Potato___Early_blight',
      'Potato___Late_blight',
      'Potato___healthy',
      'Tomato___Bacterial_spot',
      'Tomato___Early_blight',
      'Tomato___Late_blight',
      'Tomato___Leaf_Mold',
      'Tomato___Septoria_leaf_spot',
      'Tomato___Spider_mites Two-spotted_spider_mite',
      'Tomato___Target_Spot',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
      'Tomato___Tomato_mosaic_virus',
      'Tomato___healthy',
    ];

    return classIds[prediction.classIndex];
  }

  const DiseaseResultScreen({
    super.key,
    required this.imageFile,
    required this.prediction,
    required this.disease,
  });

  final File imageFile;
  final CropDiseasePrediction prediction;
  final DiseaseInformation disease;

  @override
  Widget build(BuildContext context) {
    final confidencePercent = prediction.confidence * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  imageFile,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disease.isHealthy
                            ? 'Plant appears healthy'
                            : 'Possible disease detected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        disease.diseaseName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Crop: ${disease.crop}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Confidence: ${confidencePercent.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _InformationCard(
                title: 'About this condition',
                icon: Icons.info_outline,
                child: Text(disease.description),
              ),

              if (disease.symptoms.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InformationCard(
                  title: 'Common symptoms',
                  icon: Icons.visibility_outlined,
                  child: _BulletList(items: disease.symptoms),
                ),
              ],

              const SizedBox(height: 16),

              _InformationCard(
                title: disease.isHealthy
                    ? 'Recommended care'
                    : 'Treatment & management',
                icon: Icons.local_florist_outlined,
                child: _BulletList(items: disease.treatment),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This result is an AI-based classification and '
                          'should be treated as a decision-support aid. '
                          'Confirm the diagnosis before taking significant '
                          'crop-management action.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatbotScreen(
                            prediction: _getClassId(),
                            confidence: prediction.confidence,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Ask CropCare Assistant'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Analyze another image'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
