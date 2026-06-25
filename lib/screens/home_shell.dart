import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_scope.dart';
import '../theme/app_theme.dart';
import 'create_ride_screen.dart';
import 'feed_screen.dart';
import 'login_screen.dart';
import 'my_rides_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const FeedLocation _homeLocation = FeedLocation(
    city: 'Ribeirão Preto, SP',
    lat: -21.1699,
    lng: -47.8099,
  );

  int _tabIndex = 0;
  FeedLocation _selectedLocation = _homeLocation;
  double _radiusKm = 100;
  int _feedRefreshTick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _pages),
      bottomNavigationBar: _BottomTabs(
        selectedIndex: _tabIndex,
        onTabSelected: _setTab,
      ),
    );
  }

  List<Widget> get _pages {
    return [
      FeedScreen(
        homeLocation: _homeLocation,
        selectedLocation: _selectedLocation,
        radiusKm: _radiusKm,
        feedRefreshTick: _feedRefreshTick,
        onRadiusChanged: _setRadius,
        onLocationSelected: _setSelectedLocation,
        onReturnHome: _returnHomeLocation,
      ),
      CreateRideScreen(
        isActive: _tabIndex == 1,
        onSessionExpired: _showFeed,
        onRidePublished: _onRidePublished,
      ),
      MyRidesScreen(isActive: _tabIndex == 2, onSessionExpired: _showFeed),
      ProfileScreen(onLoggedOut: _showFeed),
    ];
  }

  Future<void> _setTab(int value) async {
    if (value == 0) {
      _selectTab(value);
      return;
    }

    final auth = AuthScope.of(context);
    if (auth.isAuthenticated) {
      _selectTab(value);
      return;
    }

    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          reason: _loginReason(value),
          onGooglePressed: auth.signInWithGoogle,
        ),
      ),
    );

    if (!mounted || loggedIn != true) {
      return;
    }

    _selectTab(value);
  }

  void _selectTab(int value) => setState(() => _tabIndex = value);

  void _showFeed() => _selectTab(0);

  void _onRidePublished() {
    setState(() {
      _feedRefreshTick++;
      _tabIndex = 0;
    });
  }

  String _loginReason(int tabIndex) {
    return switch (tabIndex) {
      1 => 'Entra pra criar seu rolê e entrar na lista como organizador.',
      2 => 'Entra pra ver os rolês que você confirmou ou organizou.',
      3 => 'Entra pra ver seu perfil, moto e cidade base.',
      _ => 'Entra pra continuar no Roda Presa.',
    };
  }

  void _setRadius(double value) => setState(() => _radiusKm = value);

  void _setSelectedLocation(FeedLocation value) {
    setState(() => _selectedLocation = value);
  }

  void _returnHomeLocation() {
    setState(() => _selectedLocation = _homeLocation);
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: _selectedColor(states),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(color: _selectedColor(states), size: 24);
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTabSelected,
        height: 76,
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.paperSoft,
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.compass),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.circlePlus),
            label: 'Novo rolê',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.listUl),
            label: 'Meus rolês',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Color _selectedColor(Set<WidgetState> states) {
    return states.contains(WidgetState.selected)
        ? AppColors.orange
        : AppColors.asphalt;
  }
}
