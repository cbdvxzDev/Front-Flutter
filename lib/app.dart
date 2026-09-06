import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_airlines/core/routes/app_pages.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_theme.dart';
import 'package:royal_airlines/features/auth/controller/auth_controller.dart';
import 'package:royal_airlines/features/auth/screens/login_screen.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_store.dart';
import 'package:royal_airlines/navigation/main_navigation.dart';

/// RoyalAirlinesApp
/// ----------------
/// Widget raíz de la aplicación. Mantiene el estado global real de la
/// app en la capa funcional actual: [AuthController] para sesión y
/// [ReservationsStore] para historial de reservas.
///
/// El estado global usa los controllers y stores activos de cada modulo.
/// No se registran fuentes de estado duplicadas para mantener una sola
/// fuente de verdad durante la integracion con backend.
class RoyalAirlinesApp extends StatelessWidget {
  const RoyalAirlinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ReservationsStore()),
      ],
      child: MaterialApp(
        title: 'Royal Airlines',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
        routes: AppPages.routes,
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().tryRestoreSession();
  }

  void _syncReservationsWithSession(AuthController authController) {
    final store = context.read<ReservationsStore>();
    final user = authController.currentUser;

    if (!authController.isAuthenticated || user == null) {
      if (_loadedForUserId != null) {
        _loadedForUserId = null;
        store.clear();
      }
      return;
    }

    if (_loadedForUserId == user.id) return;
    _loadedForUserId = user.id;
    // Recupera el historial de reservas de ESTA cuenta desde disco, para
    // que no aparezca vacío cada vez que se reinicia la app o se vuelve
    // a iniciar sesión (no es solo un estado de Hot Reload).
    store.loadForUser(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        if (authController.isRestoringSession) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.4,
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncReservationsWithSession(authController);
        });

        return authController.isAuthenticated
            ? const MainNavigation()
            : const LoginScreen();
      },
    );
  }
}
