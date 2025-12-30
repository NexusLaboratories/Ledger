import 'package:flutter/material.dart';
import 'package:ledger/services/user_preference_service.dart';

class AiConfigurationDialog extends StatefulWidget {
  final String currentEndpoint;
  final String currentApiKey;
  final String currentModel;

  const AiConfigurationDialog({
    super.key,
    required this.currentEndpoint,
    required this.currentApiKey,
    required this.currentModel,
  });

  @override
  State<AiConfigurationDialog> createState() => _AiConfigurationDialogState();
}

class _AiConfigurationDialogState extends State<AiConfigurationDialog> {
  late TextEditingController _endpointController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(text: widget.currentEndpoint);
    _apiKeyController = TextEditingController(text: widget.currentApiKey);
    _modelController = TextEditingController(text: widget.currentModel);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveConfiguration() async {
    final endpoint = _endpointController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();

    if (endpoint.isEmpty || apiKey.isEmpty || model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in endpoint, API key, and model name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate URL format
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasAbsolutePath) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await UserPreferenceService.setAiEndpoint(value: endpoint);
    await UserPreferenceService.setAiApiKey(value: apiKey);
    await UserPreferenceService.setAiModel(value: model);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI configuration saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearConfiguration() async {
    await UserPreferenceService.clearAiEndpoint();
    await UserPreferenceService.clearAiApiKey();
    await UserPreferenceService.clearAiModel();

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI configuration cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Configure AI Assistant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure an OpenAI-compatible API endpoint',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                hintText: 'https://api.openai.com/v1/chat/completions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureApiKey,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model Name',
                hintText: 'gpt-4-turbo-preview',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.psychology),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentApiKey.isNotEmpty)
          TextButton(
            onPressed: _clearConfiguration,
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveConfiguration, child: const Text('Save')),
      ],
    );
  }
}
