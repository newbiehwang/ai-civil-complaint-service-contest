import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/chat/chatbot_screen.dart';
import 'screens/start/start_flow_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const CivilComplaintApp());
}

class CivilComplaintApp extends StatelessWidget {
  const CivilComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '층간소음 상담',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      home: const DemoRootScreen(),
    );
  }
}

enum RootPhase { start, chat }

class DemoRootScreen extends StatefulWidget {
  const DemoRootScreen({super.key});

  @override
  State<DemoRootScreen> createState() => _DemoRootScreenState();
}

class _DemoRootScreenState extends State<DemoRootScreen> {
  RootPhase _phase = RootPhase.start;
  int _startFlowVersion = 0;

  void _restart() {
    setState(() {
      _phase = RootPhase.start;
      _startFlowVersion += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_phase) {
      RootPhase.start => StartFlowScreen(
          key: ValueKey('start-flow-$_startFlowVersion'),
          onCompleted: () {
            setState(() {
              _phase = RootPhase.chat;
            });
          },
        ),
      RootPhase.chat => ChatbotDemoScreen(onRestart: _restart),
    };

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 480),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_phase.name),
            child: content,
          ),
        ),
      ),
    );
  }
}
