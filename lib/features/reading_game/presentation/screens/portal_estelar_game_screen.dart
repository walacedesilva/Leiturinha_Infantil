import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../services/audio_manager.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PORTAL ESTELAR — PLANETARY EXPLORATION WEBVIEW GAME SCREEN
// Renders index.html locally, running the entire generalised space exploration
// ═════════════════════════════════════════════════════════════════════════════

class PortalEstelarGameScreen extends StatefulWidget {
  const PortalEstelarGameScreen({super.key});

  @override
  State<PortalEstelarGameScreen> createState() => _PortalEstelarGameScreenState();
}

class _PortalEstelarGameScreenState extends State<PortalEstelarGameScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0520))
      ..addJavaScriptChannel(
        'WebConsole',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('🌐 JS Console: ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/portal_estelar/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0520),
      body: SafeArea(
        child: Stack(
          children: [
            // Fullscreen web game
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            
            // Sleek float loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F2FE)),
                ),
              ),
              
            // Fixed premium close button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  AudioManager().playSFX(SFXType.pop);
                  Navigator.of(context).pop();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0520).withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
