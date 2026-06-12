import 'package:flutter/material.dart';
import '../tournaments/tournaments_screen.dart';
import '../teams/teams_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TournamentsScreen(),
    const TeamsScreen(),
    const MatchesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طوبة'),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'البطولات'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'الفرق'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'المباريات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
