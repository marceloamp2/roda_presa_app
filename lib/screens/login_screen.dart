import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.reason, this.onGooglePressed});

  final String? reason;
  final Future<void> Function()? onGooglePressed;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(),
            const Spacer(),
            Text(
              'Bora rodar\njunto.',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: AppGaps.md),
            Text(
              widget.reason ??
                  'Descubra os rolês perto de você e confirme presença numa '
                      'lista que todo mundo confia.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.asphalt),
            ),
            const Spacer(),
            const _Highlights(),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppGaps.md),
              _ErrorMessage(_errorMessage!),
            ],
            const SizedBox(height: AppGaps.lg),
            _GoogleButton(
              onPressed: _isLoading ? null : _signIn,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppGaps.md),
            const _LegalNote(),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final action = widget.onGooglePressed;

    if (action == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível entrar com o Google. Tente novamente.';
      });
    }
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(
      child: Column(
        children: [
          _HighlightRow(
            icon: FontAwesomeIcons.compass,
            text: 'Acha rolês perto de você no fim de semana',
          ),
          SizedBox(height: 14),
          _HighlightRow(
            icon: FontAwesomeIcons.listCheck,
            text: 'Confirma presença numa lista só, sem zap',
          ),
          SizedBox(height: 14),
          _HighlightRow(
            icon: FontAwesomeIcons.motorcycle,
            text: 'Mostra sua moto pra galera do rolê',
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.icon, required this.text});

  final FaIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, color: AppColors.orange, size: 18),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleGlyph(),
                  const SizedBox(width: 12),
                  Text(
                    'Entrar com Google',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.paper,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const FaIcon(
        FontAwesomeIcons.google,
        color: AppColors.ink,
        size: 15,
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.asphalt,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  const _LegalNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ao entrar você concorda com os Termos de Uso e a Política de '
      'Privacidade.',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.asphalt, fontSize: 12),
    );
  }
}
