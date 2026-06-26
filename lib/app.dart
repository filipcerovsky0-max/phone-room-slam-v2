import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/mapper/presentation/mapper_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class PhoneRoomSlamApp extends StatelessWidget {
  const PhoneRoomSlamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Room SLAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MapperScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map_rounded),
      label: 'Mapa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_rounded),
      label: 'Historie',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_rounded),
      label: 'Nastavení',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Historie',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Nastavení',
          ),
        ],
      ),
    );
  }
}
