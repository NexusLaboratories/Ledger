import 'package:flutter/material.dart';

class AiSettingsSection extends StatelessWidget {
  final String apiEndpoint;
  final String apiKey;
  final String modelName;
  final VoidCallback onConfigureAi;

  const AiSettingsSection({
    super.key,
    required this.apiEndpoint,
    required this.apiKey,
    required this.modelName,
    required this.onConfigureAi,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigured = apiKey.isNotEmpty && apiEndpoint.isNotEmpty;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: const Text('AI Assistant Configuration'),
          subtitle: Text(
            isConfigured
                ? 'API configured and ready'
                : 'Configure OpenAI-compatible API',
            style: TextStyle(
              color: isConfigured ? Colors.green : Colors.orange,
            ),
          ),
          leading: Icon(
            Icons.psychology_rounded,
            color: isConfigured ? Colors.green : Colors.orange,
          ),
          onTap: onConfigureAi,
        ),
      ],
    );
  }
}
