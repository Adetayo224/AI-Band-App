import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'chats_screen.dart';
import 'device_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'talk_screen.dart';

enum AppTab { home, chats, device, settings }

/// The four tab pages plus the centre Talk button.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState of(BuildContext context) => context.findAncestorStateOfType<HomeShellState>()!;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  AppTab tab = AppTab.home;
  bool _talkOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // When the band button starts a question, open Live talk wherever we are.
      context.assistant.onBandSession = () {
        if (!_talkOpen && mounted) openTalk();
      };
    });
  }

  void goTo(AppTab t) {
    if (t == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = t);
  }

  Future<void> openTalk() async {
    if (_talkOpen) return;
    _talkOpen = true;
    await Navigator.of(context).push(riseRoute(const TalkScreen()));
    _talkOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    const pages = [HomeScreen(), ChatsScreen(), DeviceScreen(), SettingsScreen()];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: c.bg,
      child: Column(children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(tab), child: pages[tab.index]),
          ),
        ),
        AppTabBar(active: tab, onSelect: goTo, onTalk: openTalk),
      ]),
    );
  }
}

/// Bottom navigation from the design: four labelled tabs and a lime talk
/// pill in the middle. The active tab gets a small dot under its label.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.active, required this.onSelect, required this.onTalk});
  final AppTab active;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget item(AppTab t, List<IconPart> icon, String label) {
      final on = t == active;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(t),
            child: SizedBox(
              height: 56,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedScale(
                  scale: on ? 1.06 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: AppIcon(icon, size: 24, color: on ? c.text : c.muted),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 11,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                    color: on ? c.text : c.muted,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: on ? 4 : 0,
                  height: 4,
                  decoration:
                      BoxDecoration(color: c.isLight ? const Color(0xFF7FA30F) : c.accent, shape: BoxShape.circle),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: EdgeInsets.fromLTRB(10, 10, 10, bottom > 0 ? bottom : 14),
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
      child: Row(children: [
        item(AppTab.home, AppIcons.home, 'Home'),
        item(AppTab.chats, AppIcons.chat, 'Chats'),
        Expanded(
          child: Center(
            child: Pressable(
              onTap: onTalk,
              semanticLabel: 'Talk',
              child: Container(
                width: 60,
                height: 44,
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.mic, size: 22, color: c.onAccent, strokeWidth: 2),
              ),
            ),
          ),
        ),
        item(AppTab.device, AppIcons.watch, 'Device'),
        item(AppTab.settings, AppIcons.sliders, 'Settings'),
      ]),
    );
  }
}
