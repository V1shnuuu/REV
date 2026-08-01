import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ollama_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../constants/emergency_protocols.dart';

/// Optional AI triage gate shown before Live CPR Mode. This is the one place
/// in the app where the LLM does something a keyword match can't: telling
/// choking, drowning, and cardiac arrest apart from a bystander's own words,
/// and switching the protocol accordingly.
///
/// "Skip — Start CPR Now" is always on screen and never depends on the AI or
/// network — the life-saving path never waits on a classification.
class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final OllamaService _ollama = OllamaService();
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();

  bool _isListening = false;
  bool _isThinking = false;
  String? _recognizedText;
  EmergencyProtocol? _activeProtocol;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _ollama.checkAvailability();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _tts.speak(
            "Quick check — what's happening? Or say start, to begin CPR right away.");
      }
    });
  }

  @override
  void dispose() {
    _stt.stopListening();
    _tts.stop();
    super.dispose();
  }

  void _goToCpr() {
    Navigator.pushReplacementNamed(context, '/live');
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = null;
      _activeProtocol = null;
    });

    await _stt.startListening(onResult: (text) async {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _recognizedText = text;
      });

      final lower = text.toLowerCase();
      if (lower.contains('start') || lower.contains('cpr') || lower.contains('skip')) {
        _goToCpr();
        return;
      }

      if (!_ollama.isAvailable) {
        // No AI available to triage — the safe default is standard CPR,
        // never a dead end.
        _goToCpr();
        return;
      }

      setState(() => _isThinking = true);
      final result = await _ollama.classifyEmergency(text);
      if (!mounted) return;
      setState(() => _isThinking = false);

      switch (result) {
        case EmergencyType.choking:
          _showProtocol(chokingProtocol);
          break;
        case EmergencyType.drowning:
          _showProtocol(drowningProtocol);
          break;
        case EmergencyType.cardiacArrest:
        case EmergencyType.unknown:
          _goToCpr();
          break;
      }
    });
  }

  void _showProtocol(EmergencyProtocol protocol) {
    setState(() => _activeProtocol = protocol);
    _tts.speak(protocol.voiceIntro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _activeProtocol == null ? _buildAskState() : _buildProtocolState(_activeProtocol!),
              ),
            ),
            _buildSkipButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
          const Spacer(),
          Text('QUICK CHECK', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2)),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildAskState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.record_voice_over, color: const Color(0xFFE63946).withValues(alpha: 0.4), size: 64),
        const SizedBox(height: 20),
        Text(
          "What's happening?",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          "Optional — briefly describe the situation so guidance can adapt.\nOr just skip straight to CPR below.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _toggleListening,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? const Color(0xFFE63946) : const Color(0xFF1A1A2E),
              border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        if (_isThinking)
          Text('Checking protocol...', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        if (_recognizedText != null && !_isThinking)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'YOU: "$_recognizedText"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        if (!_ollama.isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'AI triage is offline right now — describing the situation will just start standard CPR.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildProtocolState(EmergencyProtocol protocol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3498DB).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3498DB).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF3498DB)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  protocol.voiceIntro,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('${protocol.label.toUpperCase()} PROTOCOL', style: GoogleFonts.inter(color: const Color(0xFFE63946), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ...protocol.steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Text('${entry.key + 1}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.4)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToCpr,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('PERSON IS UNRESPONSIVE — START CPR', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _goToCpr,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text('SKIP — START CPR NOW', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
