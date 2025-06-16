import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class ReferralRewardAnimationWidget extends StatefulWidget {
  const ReferralRewardAnimationWidget({super.key});

  @override
  State<ReferralRewardAnimationWidget> createState() =>
      _ReferralRewardAnimationWidgetState();
}

class _ReferralRewardAnimationWidgetState
    extends State<ReferralRewardAnimationWidget> {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playRewardAnimation() {
    _confettiController.play();
    _audioPlayer.play(AssetSource('sounds/horn.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _playRewardAnimation,
          icon: const Icon(Icons.celebration),
          label: const Text('Trigger Reward Animation'),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 30,
          emissionFrequency: 0.05,
          gravity: 0.3,
          colors: const [Colors.yellow, Colors.blue, Colors.red, Colors.white],
          createParticlePath: (size) {
            final path = Path();
            final rnd = Random();
            path.addOval(Rect.fromCircle(
              center: Offset(0, 0),
              radius: rnd.nextDouble() * 6 + 4,
            ));
            return path;
          },
        ),
      ],
    );
  }
}
