import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/scope.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: these must not block the first frame.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const _Boot());
}

class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  Services? _services;
  Object? _error;
  StackTrace? _stack;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final services = await Services.create();
      if (!mounted) return;
      setState(() => _services = services);
      if (services.store.band != null) {
        services.band.reconnect().then((ok) {
          if (ok) services.firmware.check();
        }).catchError((_) {});
      }
    } catch (e, s) {
      debugPrint('Startup failed: $e\n$s');
      if (!mounted) return;
      setState(() {
        _error = e;
        _stack = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_services != null) {
      return WristbandApp(services: _services!);
    }
    if (_error != null) {
      return _ErrorApp(error: _error!, stack: _stack);
    }
    return const _LoadingApp();
  }
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.accent),
          ),
        ),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error, this.stack});
  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Startup failed',
                    style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text('$error', style: TextStyle(color: colors.text, fontSize: 14)),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text('${stack ?? ''}',
                        style: TextStyle(
                            color: colors.text.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
