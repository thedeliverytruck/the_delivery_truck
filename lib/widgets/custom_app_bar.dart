import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final Widget? extraWidget;

  // ✅ Newly added parameters
  final bool showHome;
  final bool showUserHome;
  final bool showDriverHome;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.extraWidget,
    this.showHome = false,
    this.showUserHome = false,
    this.showDriverHome = false,
  }) : super(key: key);

  Future<void> _handleRoleNavigation({
    required BuildContext context,
    required String currentRole,
    required String targetRoute,
    required String loginRoute,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, loginRoute);
      return;
    }

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      final driverDoc = await firestore.collection('drivers').doc(uid).get();

      bool isUser = userDoc.exists;
      bool isDriver = driverDoc.exists;

      if ((currentRole == 'driver' && isUser) || (currentRole == 'user' && isDriver)) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Access Other Role?'),
            content: Text(
              currentRole == 'driver'
                  ? 'You are already registered as a Driver. Are you sure you want to access User features as well?'
                  : 'You are already registered as a User. Are you sure you want to access Driver features as well?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Continue')),
            ],
          ),
        );
        if (proceed != true) return;
      }

      Navigator.pushNamed(context, targetRoute);
    } catch (_) {
      Navigator.pushNamed(context, loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          Image.asset('assets/icon/icon2.png', height: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (extraWidget != null) extraWidget!,
        ],
      ),
      actions: [
        if (showHome)
          IconButton(
            icon: const Icon(LucideIcons.home, color: Colors.greenAccent),
            tooltip: 'Landing Page',
            onPressed: () => Navigator.pushNamed(context, '/landing'),
          ),
        if (showUserHome)
          IconButton(
            icon: const Icon(LucideIcons.user, color: Colors.orangeAccent),
            tooltip: 'User Home',
            onPressed: () => _handleRoleNavigation(
              context: context,
              currentRole: 'driver',
              targetRoute: '/user_home',
              loginRoute: '/login',
            ),
          ),
        if (showDriverHome)
          IconButton(
            icon: const Icon(LucideIcons.truck, color: Colors.cyanAccent),
            tooltip: 'Driver Home',
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                Navigator.pushNamed(context, '/login');
              } else {
                _handleRoleNavigation(
                  context: context,
                  currentRole: 'user',
                  targetRoute: '/driver_home',
                  loginRoute: '/login_driver',
                );
              }
            },
          ),
        IconButton(
          icon: const Icon(LucideIcons.award, color: Colors.blueAccent),
          tooltip: 'Rewards',
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              Navigator.pushNamed(context, '/rewards_info');
            } else {
              Navigator.pushNamed(context, '/rewards');
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
