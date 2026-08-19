import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/no_internet_alert_dispatcher.dart';
import 'app_alert_banner.dart';

/// Escucha [NoInternetAlertDispatcher] y muestra [AppAlertBanner] una sola vez.
class NoInternetAlertListener extends StatefulWidget {
  const NoInternetAlertListener({super.key, required this.child});

  final Widget child;

  @override
  State<NoInternetAlertListener> createState() => _NoInternetAlertListenerState();
}

class _NoInternetAlertListenerState extends State<NoInternetAlertListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = NoInternetAlertDispatcher.stream.listen((_) {
      if (!mounted) return;
      showAppAlertBanner(
        context,
        type: AppAlertType.info,
        title: 'Sin conexión a Internet',
        message: 'Verifica tu conexión e inténtalo nuevamente.',
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
