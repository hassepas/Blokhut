import 'package:flutter/material.dart';

import 'home_timer_screen.dart';
import 'overview_screen.dart';
import 'friends_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const <Widget>[
    HomeTimerScreen(),
    OverviewScreen(),
    FriendsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_rounded), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Overzicht'),
          NavigationDestination(icon: Icon(Icons.group_rounded), label: 'Vrienden'),
        ],
      ),
    );
  }
}
