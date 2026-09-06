import 'package:flutter/material.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/features/home/screens/home_screen.dart';
import 'package:royal_airlines/features/profile/screens/profile_screen.dart';
import 'package:royal_airlines/features/traveler_profile/screens/traveler_profile_screen.dart';
import 'package:royal_airlines/shared/widgets/custom_navigation_bar.dart';

/// MainNavigation
/// --------------
/// Contenedor de navegación principal: Inicio, Para ti y Perfil.
/// Usa [IndexedStack] para que cada tab mantenga su estado al cambiar.
///
/// "Mis Reservas" ([ReservationsScreen]) NO vive en este navbar: es un
/// dato 100% personal del usuario (sus propias reservas), así que se
/// accede desde dentro de [ProfileScreen] para no saturar la barra
/// principal con demasiadas opciones.
///
/// El tab "Para ti" ([TravelerProfileScreen]) clasifica al usuario en
/// un perfil de viajero (minería de datos agregada sobre TODO su
/// historial, no sobre un vuelo puntual) y lo compara con la
/// comunidad — por eso, a diferencia de un dashboard de negocio, es
/// visible para cualquier cuenta autenticada, sin distinción de roles.
///
/// Tras confirmar una compra, `success_view.dart` y `checkout_screen.dart`
/// navegan aquí y luego abren [ReservationsScreen] directamente (ya no
/// existe un tab de reservas al que saltar por índice).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _initialIndexApplied = false;

  static const List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Para ti',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  static const List<Widget> _tabs = [
    HomeScreen(),
    TravelerProfileScreen(),
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialIndexApplied) return;
    _initialIndexApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < _tabs.length) {
      setState(() => _currentIndex = args);
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }
}
