import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: child,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandIcon(),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Roda ',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  TextSpan(
                    text: 'Presa',
                    style: TextStyle(color: AppColors.orange),
                  ),
                ],
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1),
            ),
            const SizedBox(height: 5),
            const _Clock(),
          ],
        ),
      ],
    );
  }
}

// Relógio que se atualiza a cada minuto; isolado para que o setData só
// reconstrua este texto, não a marca inteira.
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDateTime(_now),
      style: const TextStyle(
        color: AppColors.asphalt,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final weekday = AppDateStrings.weekdaysShort[value.weekday - 1];
    final day = AppDateStrings.twoDigits(value.day);
    final month = AppDateStrings.twoDigits(value.month);
    final hour = AppDateStrings.twoDigits(value.hour);
    final minute = AppDateStrings.twoDigits(value.minute);

    return '$weekday, $day/$month · $hour:$minute';
  }
}

// Roda com raios e a seta de partida laranja, num selo escuro (assinatura
// da marca, definida no design em design/identidade-completa.html).
class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(11),
      ),
      child: SvgPicture.asset(
        'assets/brand/logo_mark.svg',
        width: 26,
        height: 26,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.asphalt,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.hairline);
  }
}

class Pill extends StatelessWidget {
  const Pill({required this.child, super.key, this.color, this.foreground});

  final Widget child;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.paperSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: DefaultTextStyle(
          style: TextStyle(
            color: foreground ?? AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          // Altura fixa do conteúdo para todos os pills terem a mesma altura,
          // com ícone e texto centrados verticalmente.
          child: SizedBox(
            height: 18,
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

// Título de página em dois tons: prefixo em ink, destaque em laranja
// (padrão "Meus Roles", "Meu Perfil", "Novo Role").
class TwoToneTitle extends StatelessWidget {
  const TwoToneTitle({required this.prefix, required this.highlight, super.key});

  final String prefix;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$prefix ', style: const TextStyle(color: AppColors.ink)),
          TextSpan(text: highlight, style: const TextStyle(color: AppColors.orange)),
        ],
      ),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class CardFrame extends StatelessWidget {
  const CardFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 36});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.paper,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
