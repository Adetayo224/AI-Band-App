import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'icons.dart';
import 'motion.dart';

/// Wraps any tappable thing with a soft press-down scale and a light haptic,
/// so every button in the app feels the same.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.haptic = true,
    this.pressedScale = 0.96,
    this.button = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool haptic;
  final double pressedScale;
  final bool button;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: widget.button,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The 44 point round button with a hairline border used in every header.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.foreground,
    this.borderColor,
    this.badge = false,
  });

  final List<IconPart> icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? c.surface,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor ?? c.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppIcon(icon, size: iconSize, color: foreground ?? c.text),
            if (badge)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: background ?? c.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Back button used on every pushed page.
class BackCircle extends StatelessWidget {
  const BackCircle({super.key, this.label = 'Back', this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CircleIconButton(
        icon: AppIcons.chevronLeft,
        label: label,
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
      );
}

enum ButtonTone { accent, solid, outline, ghost, danger }

/// Pill shaped button. [tone] picks the colour treatment from the design.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.tone = ButtonTone.accent,
    this.height = 56,
    this.expand = true,
    this.fontSize = 16,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final List<IconPart>? icon;
  final ButtonTone tone;
  final double height;
  final bool expand;
  final double fontSize;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    late Color bg, fg;
    Color? border;
    switch (tone) {
      case ButtonTone.accent:
        bg = c.accent;
        fg = c.onAccent;
      case ButtonTone.solid:
        bg = c.text;
        fg = c.bg;
      case ButtonTone.outline:
        bg = c.surface;
        fg = c.text;
        border = c.border;
      case ButtonTone.ghost:
        bg = Colors.transparent;
        fg = c.text;
      case ButtonTone.danger:
        bg = c.danger;
        fg = Colors.white;
    }
    final disabled = onTap == null;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        if (icon != null) ...[AppIcon(icon!, size: 18, color: fg, strokeWidth: 2), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
    return Pressable(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: fontSize >= 16 ? 20 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border == null ? null : Border.all(color: border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A simple text button (no background).
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, this.onTap, this.color, this.icon, this.size = 15});
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final List<IconPart>? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final fg = color ?? c.text;
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[AppIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
            Text(label, style: AppText.body(c, size: size, weight: FontWeight.w500, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// iOS style switch drawn to the design's size (50 by 30).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? c.accent : c.track, borderRadius: BorderRadius.circular(99)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: value ? c.onAccent : c.knob, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

class SegmentOption<T> {
  const SegmentOption(this.value, this.label);
  final T value;
  final String label;
}

/// Pill segmented control. [solid] picks text coloured selection (black on
/// white) instead of the lime accent.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.solid = false,
    this.height = 36,
    this.background,
    this.fontSize = 13,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool solid;
  final double height;
  final Color? background;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final index = math.max(0, options.indexWhere((o) => o.value == value));
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / options.length;
        return SizedBox(
          height: height,
          child: Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: w * index,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: solid ? c.text : c.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(children: [
              for (final o in options)
                Expanded(
                  child: Semantics(
                    selected: o.value == value,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(o.value);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: o.value == value ? (solid ? c.bg : c.onAccent) : c.muted,
                          ),
                          child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        );
      }),
    );
  }
}

/// Rounded surface card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppSpace.radiusCard,
    this.color,
    this.borderColor,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border),
      ),
      child: child,
    );
  }
}

/// Uppercase small section heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.overline(AppTheme.of(context)));
}

/// A small coloured status pill with a dot ("Connected", "Not connected").
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

/// Header for pushed pages: back button, title and an optional trailing item.
class SubHeader extends StatelessWidget {
  const SubHeader({super.key, required this.title, this.trailing, this.backLabel = 'Back', this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SizedBox(
      height: 44,
      child: Row(children: [
        BackCircle(label: backLabel),
        const SizedBox(width: 12),
        Expanded(
          child: subtitle == null
              ? Text(title, style: AppText.title(c), maxLines: 1, overflow: TextOverflow.ellipsis)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: AppText.title(c, size: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.muted(c, size: 12)),
                  ],
                ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// The page frame: correct background, safe area and side gutters.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.topInset, AppSpace.gutter, 24),
    this.scroll = false,
    this.bottom,
    this.safeBottom = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool scroll;
  final Widget? bottom;

  /// False for tab pages: the tab bar already handles the bottom inset.
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final body = scroll
        ? SingleChildScrollView(padding: padding, physics: const BouncingScrollPhysics(), child: child)
        : Padding(padding: padding, child: child);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: c.bg,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: safeBottom && bottom == null,
          child: Padding(
            padding: EdgeInsets.only(bottom: kb),
            child: Column(children: [
              Expanded(child: body),
              if (bottom != null) bottom!,
            ]),
          ),
        ),
      ),
    );
  }
}

/// List row with an icon, a label, optional value and chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
    this.topBorder = false,
    this.height = 50,
    this.subtitle,
  });

  final List<IconPart> icon;
  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final bool showChevron;
  final bool topBorder;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final fg = color ?? c.text;
    final row = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: topBorder ? Border(top: BorderSide(color: c.border)) : null),
      child: Row(children: [
        AppIcon(icon, size: 18, color: fg),
        const SizedBox(width: 12),
        Expanded(
          child: subtitle == null
              ? Text(label, style: AppText.body(c, size: 14, weight: FontWeight.w500, color: fg))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: AppText.body(c, size: 14, weight: FontWeight.w600, color: fg)),
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.muted(c, size: 12)),
                ]),
        ),
        if (value != null) ...[
          Text(value!, style: AppText.body(c, size: 14, color: c.muted)),
          const SizedBox(width: 6),
        ],
        if (trailing != null)
          trailing!
        else if (showChevron && onTap != null)
          AppIcon(AppIcons.chevronRight, size: 16, color: c.muted, strokeWidth: 2),
      ]),
    );
    if (onTap == null) return row;
    return Pressable(onTap: onTap, pressedScale: 0.98, child: row);
  }
}

/// Card that groups [ListRow]s with dividers between them.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(children: children),
    );
  }
}

/// Text field styled like the design (52 high, 16 radius, surface fill).
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.optional = false,
    this.keyboardType,
    this.obscure = false,
    this.mono = false,
    this.onChanged,
    this.autofillHints,
    this.suffix,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool optional;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool mono;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c.border),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(text: label),
          if (optional) const TextSpan(text: '  Optional', style: TextStyle(fontWeight: FontWeight.w400)),
        ]),
        style: AppText.body(c, size: 13, weight: FontWeight.w500, color: c.muted),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: onChanged,
        autofillHints: autofillHints,
        textInputAction: textInputAction ?? TextInputAction.next,
        cursorColor: c.accent,
        style: TextStyle(
          fontFamily: mono ? AppFonts.mono : AppFonts.sans,
          fontSize: mono ? 15 : 16,
          color: c.text,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 16, color: c.muted.withValues(alpha: 0.8)),
          filled: true,
          fillColor: c.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: border,
          border: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
          suffixIcon: suffix,
        ),
      ),
    ]);
  }
}

/// Three-part date input: Day / Month / Year. Reads and writes the combined
/// value "DD.MM.YYYY" through [controller] so storage stays unchanged.
class BirthdayField extends StatefulWidget {
  const BirthdayField({super.key, required this.controller, this.label = 'Birthday', this.onChanged});

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  State<BirthdayField> createState() => _BirthdayFieldState();
}

class _BirthdayFieldState extends State<BirthdayField> {
  late final TextEditingController _d;
  late final TextEditingController _m;
  late final TextEditingController _y;
  final _dFocus = FocusNode();
  final _mFocus = FocusNode();
  final _yFocus = FocusNode();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final parts = _split(widget.controller.text);
    _d = TextEditingController(text: parts.$1);
    _m = TextEditingController(text: parts.$2);
    _y = TextEditingController(text: parts.$3);
    widget.controller.addListener(_pullFromParent);
  }

  (String, String, String) _split(String v) {
    final parts = v.split('.');
    String p(int i) => i < parts.length ? parts[i] : '';
    return (p(0), p(1), p(2));
  }

  void _pullFromParent() {
    if (_syncing) return;
    final parts = _split(widget.controller.text);
    if (parts.$1 != _d.text) _d.text = parts.$1;
    if (parts.$2 != _m.text) _m.text = parts.$2;
    if (parts.$3 != _y.text) _y.text = parts.$3;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_pullFromParent);
    _d.dispose();
    _m.dispose();
    _y.dispose();
    _dFocus.dispose();
    _mFocus.dispose();
    _yFocus.dispose();
    super.dispose();
  }

  void _push() {
    final combined = (_d.text.isEmpty && _m.text.isEmpty && _y.text.isEmpty) ? '' : '${_d.text}.${_m.text}.${_y.text}';
    if (combined == widget.controller.text) return;
    _syncing = true;
    widget.controller.text = combined;
    _syncing = false;
    widget.onChanged?.call(combined);
  }

  void _onChanged(TextEditingController ctrl, int maxLen, FocusNode? next) {
    if (ctrl.text.length >= maxLen && next != null) next.requestFocus();
    _push();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: AppText.body(c, size: 13, weight: FontWeight.w500, color: c.muted)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(flex: 2, child: _part(c, _d, _dFocus, 'DD', 2, _mFocus)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _part(c, _m, _mFocus, 'MM', 2, _yFocus)),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _part(c, _y, _yFocus, 'YYYY', 4, null)),
      ]),
    ]);
  }

  Widget _part(AppColors c, TextEditingController ctrl, FocusNode focus, String hint, int maxLen, FocusNode? next) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c.border),
    );
    return TextField(
      controller: ctrl,
      focusNode: focus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLen,
      cursorColor: c.accent,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _onChanged(ctrl, maxLen, next),
      style: TextStyle(fontFamily: AppFonts.mono, fontSize: 15, color: c.text),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(fontFamily: AppFonts.mono, fontSize: 15, color: c.muted.withValues(alpha: 0.8)),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        enabledBorder: border,
        border: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
      ),
    );
  }
}

/// Square-ish icon tile with a tinted background (used in lists and cards).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
    this.circle = false,
  });

  final List<IconPart> icon;
  final Color background;
  final Color foreground;
  final double size;
  final double radius;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: AppIcon(icon, size: iconSize, color: foreground),
    );
  }
}

/// Drawn wristband mark from the design: outer ring (optionally a battery
/// progress ring), inner face, button dot and speaker holes.
class BandMark extends StatelessWidget {
  const BandMark({
    super.key,
    this.size = 104,
    this.progress,
    this.dashed = false,
    this.ringColor,
    this.dotColor,
    this.strokeWidth = 4,
    this.showSpeaker = true,
    this.showClasp = true,
    this.opacity = 1,
  });

  final double size;
  final double? progress;
  final bool dashed;
  final Color? ringColor;
  final Color? dotColor;
  final double strokeWidth;
  final bool showSpeaker;
  final bool showClasp;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Opacity(
      opacity: opacity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress ?? 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, p, _) => CustomPaint(
          size: Size.square(size),
          painter: _BandPainter(
            c: c,
            progress: progress == null ? null : p,
            dashed: dashed,
            ringColor: ringColor ?? c.accent,
            dotColor: dotColor ?? c.accent,
            strokeWidth: strokeWidth,
            showSpeaker: showSpeaker,
            showClasp: showClasp,
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.c,
    required this.progress,
    required this.dashed,
    required this.ringColor,
    required this.dotColor,
    required this.strokeWidth,
    required this.showSpeaker,
    required this.showClasp,
  });

  final AppColors c;
  final double? progress;
  final bool dashed;
  final Color ringColor;
  final Color dotColor;
  final double strokeWidth;
  final bool showSpeaker;
  final bool showClasp;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 104);
    const center = Offset(52, 52);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      ring.color = c.track;
      const segments = 25;
      const sweep = 2 * math.pi / segments;
      for (var i = 0; i < segments; i++) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: 48), i * sweep, sweep * 0.5, false, ring);
      }
    } else if (progress != null) {
      ring.color = c.track;
      canvas.drawCircle(center, 48, ring);
      ring.color = ringColor;
      canvas.drawArc(Rect.fromCircle(center: center, radius: 48), -math.pi / 2, 2 * math.pi * progress!, false, ring);
    } else {
      ring.color = ringColor;
      canvas.drawCircle(center, 48, ring);
    }
    canvas.drawCircle(center, 34, Paint()..color = c.surface2);
    canvas.drawCircle(
        center,
        34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = c.border);
    canvas.drawCircle(center, 25, Paint()..color = c.bg);
    canvas.drawCircle(const Offset(52, 38), 2.5, Paint()..color = dotColor);
    if (showSpeaker) {
      final holes = Paint()..color = c.faint;
      for (final o in const [Offset(46, 58), Offset(52, 58), Offset(58, 58), Offset(49, 63), Offset(55, 63)]) {
        canvas.drawCircle(o, 1.4, holes);
      }
    }
    if (showClasp && progress != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(85, 46, 5, 12), const Radius.circular(2)),
        Paint()..color = c.faint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.progress != progress || old.c != c || old.dashed != dashed || old.ringColor != ringColor;
}

/// Small dot, used for unread and status markers.
class Dot extends StatelessWidget {
  const Dot({super.key, required this.color, this.size = 6});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Stepped progress bar used in onboarding ("1 of 4").
class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step, this.total = 4, this.errorStep});
  final int step;
  final int total;
  final int? errorStep;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Row(children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: 4,
            decoration: BoxDecoration(
              color: i == errorStep ? c.danger : (i <= step ? c.accent : c.track),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    ]);
  }
}

/// Progress bar with the moving shine, used for firmware updates.
class ShineProgress extends StatelessWidget {
  const ShineProgress({super.key, required this.value, this.height = 8});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: height,
        color: c.track,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 400),
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(color: c.accent, child: const Shine()),
            ),
          ),
        ),
      ),
    );
  }
}

/// A modal bottom sheet styled like the design (used for confirmations).
Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  List<IconPart>? icon,
  bool danger = true,
}) {
  final c = AppTheme.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    isScrollControlled: true,
    builder: (ctx) => AppTheme(
      colors: c,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 20),
          if (icon != null) ...[
            IconTile(
              icon: icon,
              background: danger ? c.dangerSoft : c.accentSoft,
              foreground: danger ? c.danger : c.accentText,
              size: 56,
              iconSize: 26,
              circle: true,
            ),
            const SizedBox(height: 14),
          ],
          Text(title, style: AppText.title(c)),
          const SizedBox(height: 14),
          Text(message, style: AppText.body(c, color: c.muted, height: 1.5)),
          const SizedBox(height: 20),
          PillButton(
            label: confirmLabel,
            height: 54,
            tone: danger ? ButtonTone.danger : ButtonTone.accent,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 6),
          Center(child: LinkButton(label: 'Cancel', onTap: () => Navigator.of(ctx).pop(false))),
        ]),
      ),
    ),
  );
}

/// Shows a short message at the bottom of the screen in the app's style.
void showToast(BuildContext context, String message) {
  final c = AppTheme.of(context);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      content: Text(message, style: AppText.body(c, size: 14, color: c.bg, weight: FontWeight.w500)),
      duration: const Duration(seconds: 2),
    ));
}

/// Keeps a looping animation still when reduced motion is requested.
Widget maybeStill(BuildContext context, Widget animated, Widget still) => reduceMotion(context) ? still : animated;
