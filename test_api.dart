import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('.env not found');
    return;
  }
  
  final lines = envFile.readAsLinesSync();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty || apiKey.startsWith('AQ')) {
    print('Invalid API Key in .env: $apiKey');
    return;
  }

  // Use HttpClient or dart:io Process to call curl
  final result = await Process.run('curl', [
    '-s',
    'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'
  ]);
  
  print('--- MODELS JSON ---');
  print(result.stdout);
  print('--- ERRORS ---');
  print(result.stderr);
}
