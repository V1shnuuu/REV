import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/emergency_protocols.dart';

class OllamaService {
  // Active ngrok tunnel for judges to access Gemma 4.
  // Exposed as a host constant so the TLS trust override in main.dart can be
  // scoped to exactly this host instead of bypassing certificate checks app-wide.
  static const String ngrokHost = 'coping-gainfully-grievous.ngrok-free.dev';
  static const String _baseUrl = 'https://$ngrokHost';
  static const String _model = 'gemma4:latest';
  static const String _systemPrompt = '''
You are a highly concise AI CPR coach.
Your task is to provide EXACTLY ONE short, highly practical tip (max 15 words) on how to perform the requested step safely and effectively.
Rule 1: Focus purely on practical advice for the specific step requested.
Rule 2: Never mention chest compressions or rescue breaths UNLESS the step explicitly mentions them.
Rule 3: Keep it strictly under 15 words.
Rule 4: Start directly with a strong action verb. NEVER start with "Your", "The", or "This".
Rule 5: Use simple language. Avoid medical jargon like "supine" (use "on their back") or "sternum" (use "center of chest").
''';

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Check if Ollama is running and reachable
  Future<bool> checkAvailability() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/tags'),
            headers: {
              'ngrok-skip-browser-warning': '69420',
              'User-Agent': 'FlutterApp',
            },
          )
          .timeout(const Duration(seconds: 5));
      _isAvailable = response.statusCode == 200;
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  /// Helper to call Ollama chat API with proper message format
  Future<String?> _chatRequest({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.4,
    int numPredict = 500,
    int timeoutSeconds = 90,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': '69420',
              'User-Agent': 'FlutterApp',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'stream': false,
              'options': {
                'temperature': temperature,
                'num_predict': numPredict,
              },
            }),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      print('Ollama Chat Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? content = data['message']?['content']?.toString().trim();
        
        if (content != null && content.isNotEmpty) {
          print('Ollama Raw Content: $content');
          
          // Strip XML/HTML-like reasoning tags: <think>...</think> or <thinking>...</thinking>
          content = content.replaceAll(RegExp(r'<(think|thinking)>[\s\S]*?</\1>', caseSensitive: false), '').trim();
          
          // Also strip common markdown/plain-text thinking blocks
          content = content.replaceAll(RegExp(r'^Thinking Process:?\s*', caseSensitive: false), '').trim();
          
          // Clean up any remaining leading/trailing markdown blocks or lines
          content = content.trim();
          
          print('Ollama Chat Success Cleaned Content: $content');
          return content;
        } else {
          print('Ollama Chat Empty Content: ${response.body}');
        }
      } else {
        print('Ollama Chat Error Body: ${response.body}');
      }
      return null;
    } catch (e, stack) {
      print('Ollama Chat Exception: $e\n$stack');
      return null;
    }
  }

  /// Generate a calming AI tip for a given CPR step
  Future<String?> generateTip(String stepTitle, String stepDescription) async {
    return _chatRequest(
      systemPrompt: _systemPrompt,
      userMessage: 'Step: "$stepTitle"\nInstruction: "$stepDescription"\n\nProvide one actionable tip.',
      temperature: 0.4,
      numPredict: 150, // Increased to give reasoning models buffer
      timeoutSeconds: 20,
    );
  }

  /// Get encouragement during active CPR
  Future<String?> getEncouragement() async {
    return _chatRequest(
      systemPrompt: _systemPrompt,
      userMessage: 'The user is doing CPR compressions right now. Give ONE short sentence of encouragement. Be calm and supportive.',
      temperature: 0.5,
      numPredict: 100, // Increased to give reasoning models buffer
      timeoutSeconds: 15,
    );
  }

  /// Conversational chat for the Voice Assistant / Ask Gemma feature
  static const String _chatSystemPrompt = '''
You are a helpful first-aid assistant.
Rule: Provide the direct final answer immediately.
Never write down your thinking process, plans, steps, thoughts, or <thinking> tags.
Answer in under 15 words.
''';

  Future<String?> chatAnswer(String userQuestion) async {
    return _chatRequest(
      systemPrompt: _chatSystemPrompt,
      userMessage: userQuestion,
      temperature: 0.1,
      numPredict: 800, // Increased to 800 so reasoning models complete both thinking and final answer!
      timeoutSeconds: 90, // Increased to 90s to prevent timing out on slower local runs
    );
  }

  /// High-speed conversational response for emergency mode
  Future<String?> emergencyChatAnswer(String userQuestion) async {
    return _chatRequest(
      systemPrompt: "You are an emergency CPR coach. Answer in under 8 words. Be direct. Do not explain.",
      userMessage: userQuestion,
      temperature: 0.1,
      numPredict: 500, // Increased to 500 to give reasoning models buffer
      timeoutSeconds: 30,
    );
  }

  /// This is the one job in the app an LLM is actually needed for: turning a
  /// bystander's free-form, panicked description into the right protocol.
  /// Choking, drowning, and cardiac arrest need different first actions —
  /// keyword matching can't reliably tell "he's turning blue and can't talk"
  /// (choking) apart from "he's turning blue and not moving" (cardiac).
  static const String _triageSystemPrompt = '''
You are an emergency triage classifier for a bystander CPR app. Read the bystander's spoken description of what is happening and classify it into EXACTLY ONE category.

CARDIAC: person is unconscious, unresponsive, not breathing normally, collapsed, no pulse, possible heart attack.
CHOKING: person is conscious, coughing, clutching their throat, can't speak or breathe because of a stuck object or food.
DROWNING: person was pulled from water, near-drowning, swallowed water, water rescue.
UNKNOWN: description is unclear, unrelated, or does not clearly match any of the above.

Respond with ONLY one word: CARDIAC, CHOKING, DROWNING, or UNKNOWN. No punctuation, no explanation.
''';

  /// Defaults to [EmergencyType.unknown] on any failure/timeout/ambiguous
  /// reply — callers must treat unknown exactly like cardiac arrest and
  /// route to standard CPR, since that is the safe default when uncertain.
  Future<EmergencyType> classifyEmergency(String description) async {
    final result = await _chatRequest(
      systemPrompt: _triageSystemPrompt,
      userMessage: description,
      temperature: 0.0,
      numPredict: 10,
      timeoutSeconds: 15,
    );

    if (result == null) return EmergencyType.unknown;
    final upper = result.toUpperCase();
    if (upper.contains('CHOKING')) return EmergencyType.choking;
    if (upper.contains('DROWNING')) return EmergencyType.drowning;
    if (upper.contains('CARDIAC')) return EmergencyType.cardiacArrest;
    return EmergencyType.unknown;
  }
}
