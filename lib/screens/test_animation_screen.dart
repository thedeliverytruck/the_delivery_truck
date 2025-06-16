import 'package:flutter/material.dart';
import '../widgets/referral_reward_animation_widget.dart';

class TestAnimationScreen extends StatelessWidget {
  const TestAnimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ReferralRewardAnimationWidget(),
      ),
    );
  }
}
