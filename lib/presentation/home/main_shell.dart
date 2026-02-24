import 'package:flutter/material.dart';

import '../auth/profile/profile_colors.dart';
import '../auth/profile/profile_page.dart';
import 'drawer/app_drawer.dart';
import 'bottom_navigation/home_tab.dart';
import 'bottom_navigation/placeholder_tab.dart';
import 'bottom_navigation/historial_tab.dart';
import '../turnos/historial_turnos/historial_turnos_page.dart';
import '../turnos/control_turnos_page.dart';
import '../turnos/inicio_turno/inicio_turno_page.dart';
import '../turnos/captura_odometro/captura_odometro_page.dart';
import '../turnos/registro_combustible/registro_combustible_page.dart';
import '../turnos/resumen_turno/resumen_turno_page.dart';
import '../turnos/reporte_incidente/reporte_incidente_page.dart';
import '../turnos/escanear_vehiculo/escanear_vehiculo_page.dart';
import '../turnos/registro_danos/registro_danos_page.dart';
import '../turnos/indicadores_testigo/indicadores_testigo_page.dart';
import '../turnos/niveles_fluido/niveles_fluido_page.dart';
import '../turnos/luces_vehiculo/luces_vehiculo_page.dart';
import '../turnos/accesorios/accesorios_page.dart';
import '../turnos/documentacion/documentacion_page.dart';
import '../turnos/models/checklist_type.dart';

/// Índices de los tabs del BottomNavigation (global).
enum MainShellTab { home, turnos, historial, profile }

/// Shell principal: drawer + NavigationBar global + body (tabs o Control de Turnos).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  MainShellTab _selectedTab = MainShellTab.home;
  bool _showControlTurnos = false;

  void _onControlTurnosTap() {
    Navigator.pop(context);
    setState(() {
      _showControlTurnos = true;
      _selectedTab = MainShellTab.turnos;
    });
  }

  void _onHistorialTap() {
    Navigator.pop(context);
    setState(() {
      _showControlTurnos = false;
      _selectedTab = MainShellTab.historial;
    });
  }

  void _onProfileTap() {
    Navigator.pop(context);
    setState(() {
      _showControlTurnos = false;
      _selectedTab = MainShellTab.profile;
    });
  }

  void _onBackFromControlTurnos() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else {
      setState(() {
        _showControlTurnos = false;
        _selectedTab = MainShellTab.home;
      });
    }
  }

  Widget _buildBody() {
    if (_selectedTab == MainShellTab.historial) {
      return HistorialTurnosPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      );
    }
    if (_showControlTurnos) {
      return Navigator(
        key: _navigatorKey,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute<void>(
              builder: (_) => ControlTurnosPage(
                onBack: _onBackFromControlTurnos,
                onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                onAperturaTap: () => _navigatorKey.currentState?.pushNamed('/inicio-turno'),
                onCierreTap: () => _navigatorKey.currentState?.pushNamed('/cierre-turno'),
                onReportarIncidenteTap: () => _navigatorKey.currentState?.pushNamed('/reporte-incidente'),
                onRegistroCombustibleTap: () => _navigatorKey.currentState?.pushNamed('/registro-combustible'),
              ),
            );
          }
          if (settings.name == '/inicio-turno') {
            return MaterialPageRoute<void>(
              builder: (_) => InicioTurnoPage(
                onSiguienteTap: () => _navigatorKey.currentState?.pushNamed('/captura-odometro'),
                onEscanearVehiculoTap: () => _navigatorKey.currentState?.pushNamed('/escanear-vehiculo'),
              ),
            );
          }
          if (settings.name == '/escanear-vehiculo') {
            return MaterialPageRoute<void>(
              builder: (_) => EscanearVehiculoPage(
                onVehiculoEscaneado: (vehiculoId) {
                  _navigatorKey.currentState?.pop(vehiculoId);
                },
                onIngresarManualmente: () {
                  _navigatorKey.currentState?.pop();
                },
              ),
            );
          }
          if (settings.name == '/captura-odometro') {
            return MaterialPageRoute<void>(
              builder: (_) => CapturaOdometroPage(
                onSiguienteTap: () => _navigatorKey.currentState?.pushNamed('/registro-danos'),
              ),
            );
          }
          if (settings.name == '/registro-danos') {
            return MaterialPageRoute<void>(
              builder: (_) => RegistroDanosPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/indicadores-testigo'),
              ),
            );
          }
          if (settings.name == '/indicadores-testigo') {
            return MaterialPageRoute<void>(
              builder: (_) => IndicadoresTestigoPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/niveles-fluido'),
              ),
            );
          }
          if (settings.name == '/niveles-fluido') {
            return MaterialPageRoute<void>(
              builder: (_) => NivelesFluidoPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/luces-vehiculo'),
              ),
            );
          }
          if (settings.name == '/luces-vehiculo') {
            return MaterialPageRoute<void>(
              builder: (_) => LucesVehiculoPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/accesorios'),
              ),
            );
          }
          if (settings.name == '/accesorios') {
            return MaterialPageRoute<void>(
              builder: (_) => AccesoriosPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/documentacion'),
              ),
            );
          }
          if (settings.name == '/documentacion') {
            return MaterialPageRoute<void>(
              builder: (_) => DocumentacionPage(
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/resumen-turno'),
              ),
            );
          }
          if (settings.name == '/registro-combustible') {
            return MaterialPageRoute<void>(
              builder: (_) => const RegistroCombustiblePage(),
            );
          }
          if (settings.name == '/resumen-turno') {
            return MaterialPageRoute<void>(
              builder: (_) => const ResumenTurnoPage(),
            );
          }
          if (settings.name == '/cierre-turno') {
            return MaterialPageRoute<void>(
              builder: (_) => InicioTurnoPage(
                checklistType: ChecklistType.cierre,
                onSiguienteTap: () => _navigatorKey.currentState?.pushNamed('/cierre-captura-odometro'),
                onEscanearVehiculoTap: () => _navigatorKey.currentState?.pushNamed('/escanear-vehiculo'),
              ),
            );
          }
          if (settings.name == '/cierre-captura-odometro') {
            return MaterialPageRoute<void>(
              builder: (_) => CapturaOdometroPage(
                checklistType: ChecklistType.cierre,
                onSiguienteTap: () => _navigatorKey.currentState?.pushNamed('/cierre-registro-danos'),
              ),
            );
          }
          if (settings.name == '/cierre-registro-danos') {
            return MaterialPageRoute<void>(
              builder: (_) => RegistroDanosPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-indicadores-testigo'),
              ),
            );
          }
          if (settings.name == '/cierre-indicadores-testigo') {
            return MaterialPageRoute<void>(
              builder: (_) => IndicadoresTestigoPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-niveles-fluido'),
              ),
            );
          }
          if (settings.name == '/cierre-niveles-fluido') {
            return MaterialPageRoute<void>(
              builder: (_) => NivelesFluidoPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-luces-vehiculo'),
              ),
            );
          }
          if (settings.name == '/cierre-luces-vehiculo') {
            return MaterialPageRoute<void>(
              builder: (_) => LucesVehiculoPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-accesorios'),
              ),
            );
          }
          if (settings.name == '/cierre-accesorios') {
            return MaterialPageRoute<void>(
              builder: (_) => AccesoriosPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-documentacion'),
              ),
            );
          }
          if (settings.name == '/cierre-documentacion') {
            return MaterialPageRoute<void>(
              builder: (_) => DocumentacionPage(
                checklistType: ChecklistType.cierre,
                onContinuar: () => _navigatorKey.currentState?.pushNamed('/cierre-resumen-turno'),
              ),
            );
          }
          if (settings.name == '/cierre-resumen-turno') {
            return MaterialPageRoute<void>(
              builder: (_) => const ResumenTurnoPage(checklistType: ChecklistType.cierre),
            );
          }
          if (settings.name == '/reporte-incidente') {
            return MaterialPageRoute<void>(
              builder: (_) => const ReporteIncidentePage(),
            );
          }
          return null;
        },
      );
    }
    return _TabContent(
      selectedTab: _selectedTab,
      onDrawerOpen: () => _scaffoldKey.currentState?.openDrawer(),
      onComenzarTap: () => setState(() {
            _showControlTurnos = true;
            _selectedTab = MainShellTab.turnos;
          }),
    );
  }

  int get _effectiveSelectedIndex {
    if (_showControlTurnos) return MainShellTab.turnos.index;
    return _selectedTab.index;
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedTab = MainShellTab.values[index];
      _showControlTurnos = (_selectedTab == MainShellTab.turnos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onControlTurnosTap: _onControlTurnosTap,
        onHistorialTap: _onHistorialTap,
        onProfileTap: _onProfileTap,
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _effectiveSelectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Turnos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.selectedTab,
    required this.onDrawerOpen,
    this.onComenzarTap,
  });

  final MainShellTab selectedTab;
  final VoidCallback onDrawerOpen;
  final VoidCallback? onComenzarTap;

  Widget _buildPage(MainShellTab tab) {
    return switch (tab) {
      MainShellTab.home => HomeTab(onComenzarTap: onComenzarTap),
      MainShellTab.turnos => const PlaceholderTab(title: 'Turnos'),
      MainShellTab.historial => const HistorialTab(),
      MainShellTab.profile => const ProfilePage(),
    };
  }

  String _titleFor(MainShellTab tab) {
    return switch (tab) {
      MainShellTab.home => 'Bienvenido',
      MainShellTab.turnos => 'Turnos',
      MainShellTab.historial => 'Historial',
      MainShellTab.profile => 'Perfil',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: ProfileColors.background(context),
          foregroundColor: ProfileColors.textPrimary(context),
          title: Text(
            _titleFor(selectedTab),
            style: TextStyle(
              color: ProfileColors.textPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.menu, color: ProfileColors.textPrimary(context)),
            onPressed: onDrawerOpen,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: selectedTab.index,
            children: MainShellTab.values.map(_buildPage).toList(),
          ),
        ),
      ],
    );
  }
}
