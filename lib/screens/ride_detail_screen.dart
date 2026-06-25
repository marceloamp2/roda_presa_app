import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_scope.dart';
import '../models/ride.dart';
import '../models/ride_user.dart';
import '../services/google_identity_service.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confirm_cancel_dialog.dart';
import 'create_ride_screen.dart';

class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({required this.ride, super.key});

  final Ride ride;

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

extension RideNavigation on BuildContext {
  Future<void> openRide(Ride ride) {
    return Navigator.of(this).push(
      MaterialPageRoute<void>(builder: (_) => RideDetailScreen(ride: ride)),
    );
  }
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final RideApiService _rideApiService = RideApiService();

  late Ride _ride;
  bool _submitting = false;
  bool _loadingDetails = false;
  String? _detailsError;
  int _requestVersion = 0;

  RideUser? get _currentUserConfirmation {
    final userId = AuthScope.of(context).user?.id;

    if (userId == null) {
      return null;
    }

    return _ride.users.where((user) => user.id == userId).firstOrNull;
  }

  bool get _hasJoinedRide => _currentUserConfirmation != null;

  bool get _isOrganizer => _currentUserConfirmation?.organizer == true;

  bool get _isRideCanceled => _ride.canceled;

  bool get _canEditRide {
    return _isOrganizer && !_isRideCanceled && !_submitting && !_isPastRide;
  }

  bool get _isPastRide {
    final rideDate = DateTime.tryParse(_ride.editData.rideDate);

    if (rideDate == null) {
      return false;
    }

    final today = DateUtils.dateOnly(DateTime.now());

    return DateUtils.dateOnly(rideDate).isBefore(today);
  }

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _loadDetails();
  }

  @override
  void dispose() {
    _rideApiService.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RideDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.ride.id != widget.ride.id) {
      _ride = widget.ride;
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        child: ListView(
          children: [
            _DetailTop(
              ride: _ride,
              onEdit: _canEditRide ? _editRide : null,
              onCancel: _isOrganizer && !_isRideCanceled && !_submitting
                  ? _confirmCancel
                  : null,
            ),
            const SizedBox(height: AppGaps.lg),
            _BriefingGrid(ride: _ride),
            const SizedBox(height: AppGaps.lg),
            _ConfirmedList(
              ride: _ride,
              currentUserId: AuthScope.of(context).user?.id,
              loadingDetails: _loadingDetails,
              detailsError: _detailsError,
              onRetry: _loadDetails,
              onLeave: _submitting || _isRideCanceled ? null : _leave,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        onShare: _shareOnWhatsApp,
        onJoin: _submitting || _isRideCanceled
            ? null
            : (_hasJoinedRide ? _leave : _handleJoin),
        joined: _hasJoinedRide,
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    final whatsAppUrl = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_ride.shareText)}',
    );

    final launched = await launchUrl(
      whatsAppUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted || launched) return;
    AppSnackBar.showError(context, 'Não foi possível abrir o WhatsApp.');
  }

  Future<void> _loadDetails() async {
    if (_ride.id <= 0) {
      return;
    }

    final requestVersion = ++_requestVersion;

    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });

    try {
      final ride = await _rideApiService.fetchRide(_ride.id);

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _ride = ride;
        _loadingDetails = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _loadingDetails = false;
        _detailsError = 'Não foi possível carregar a lista completa agora.';
      });
    }
  }

  void _handleJoin() {
    if (AuthScope.of(context).isAuthenticated) {
      _confirm();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _LoginSheet(ride: _ride, onContinue: _signInThenConfirm),
    );
  }

  Future<void> _signInThenConfirm() async {
    try {
      await AuthScope.of(context).signInWithGoogle();
    } catch (exception) {
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.showError(
        context,
        googleSignInErrorMessage(
          exception,
          fallback: 'Não foi possível entrar com o Google.',
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    _confirm();
  }

  Future<void> _confirm() async {
    final token = AuthScope.of(context).token;

    if (token == null || token.isEmpty) {
      AppSnackBar.showError(context, 'Entre novamente para entrar na lista.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final ride = await _rideApiService.confirmPresence(
        rideId: _ride.id,
        authToken: token,
      );

      if (!mounted) return;
      setState(() {
        _ride = ride;
        _submitting = false;
      });
      AppSnackBar.showSuccess(context, 'Você entrou na lista.');
    } catch (exception) {
      await _handleSubmitError(exception);
    }
  }

  Future<void> _leave() async {
    final token = AuthScope.of(context).token;

    if (token == null || token.isEmpty) {
      AppSnackBar.showError(context, 'Entre novamente para sair da lista.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final ride = await _rideApiService.leaveRide(
        rideId: _ride.id,
        authToken: token,
      );

      if (!mounted) return;
      setState(() {
        _ride = ride;
        _submitting = false;
      });
      AppSnackBar.showSuccess(context, 'Você saiu da lista.');
    } catch (exception) {
      await _handleSubmitError(exception);
    }
  }

  Future<void> _editRide() async {
    final saved = await context.editRide(_ride);

    if (saved == true && mounted) {
      await _loadDetails();
    }
  }

  Future<void> _confirmCancel() async {
    if (await showCancelRideDialog(context) && mounted) {
      await _cancel();
    }
  }

  Future<void> _cancel() async {
    final token = AuthScope.of(context).token;

    if (token == null || token.isEmpty) {
      AppSnackBar.showError(context, 'Entre novamente para cancelar o rolê.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await _rideApiService.cancelRide(rideId: _ride.id, authToken: token);

      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.showSuccess(context, 'Rolê cancelado.');
      await _loadDetails();
    } catch (exception) {
      await _handleSubmitError(exception);
    }
  }

  Future<void> _handleSubmitError(Object exception) async {
    if (!mounted) return;
    setState(() => _submitting = false);

    if (await AuthScope.of(context).handleApiException(exception)) {
      return;
    }

    if (!mounted) return;
    AppSnackBar.showError(
      context,
      'Não foi possível atualizar sua presença agora.',
      exception: exception,
    );
  }
}

class _DetailTop extends StatelessWidget {
  const _DetailTop({required this.ride, this.onEdit, this.onCancel});

  final Ride ride;

  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                  label: const Text('voltar'),
                ),
              ),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: AppColors.blue),
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                label: const Text('Editar'),
              ),
            if (onCancel != null)
              TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                label: const Text('Cancelar rolê'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              ride.hot ? 'Rolê · 🔥 enchendo' : 'Rolê',
              style: const TextStyle(
                color: AppColors.asphalt,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (ride.canceled) ...[
              const SizedBox(width: 8),
              const Pill(
                color: AppColors.redSoft,
                foreground: AppColors.red,
                child: Text('cancelado'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ride.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(color: AppColors.inkMedium),
        ),
      ],
    );
  }
}

class _BriefingGrid extends StatelessWidget {
  const _BriefingGrid({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final hasNotes = ride.notes.isNotEmpty;

    return CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BriefRow(label: 'Data', value: '${ride.date} - ${ride.weekday}'),
          _BriefRow(label: 'Destino', value: ride.destination),
          _BriefRow(label: 'Ponto de partida', value: ride.departureSummary),
          _BriefRow(label: 'Hora do briefing', value: ride.briefing),
          _BriefRow(label: 'Hora da saída', value: ride.time),
          _BriefRow(label: 'Pedágios (ida e volta)', value: ride.tolls),
          _BriefRow(label: 'Distância', value: '${ride.distanceKm} km'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: AppColors.paperSoft),
          ),
          const SectionLabel('Observações'),
          const SizedBox(height: 6),
          Text(
            hasNotes ? ride.notes : 'Sem observações',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: hasNotes ? AppColors.ink : AppColors.asphalt,
            ),
          ),
        ],
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedList extends StatelessWidget {
  const _ConfirmedList({
    required this.ride,
    required this.currentUserId,
    required this.loadingDetails,
    required this.detailsError,
    required this.onRetry,
    required this.onLeave,
  });

  final Ride ride;
  final int? currentUserId;
  final bool loadingDetails;
  final String? detailsError;
  final VoidCallback onRetry;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lista de confirmados',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.inkMedium,
                  fontSize: 24,
                ),
              ),
            ),
            Text(
              '${ride.baseConfirmedCount}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loadingDetails) const LinearProgressIndicator(minHeight: 2),
        if (detailsError != null && ride.users.isEmpty)
          _ConfirmedListMessage(message: detailsError!, onRetry: onRetry),
        for (var index = 0; index < ride.users.length; index++)
          _PersonRow(
            number: '${index + 1}',
            user: ride.users[index],
            onLeave: ride.users[index].id == currentUserId ? onLeave : null,
          ),
      ],
    );
  }
}

class _ConfirmedListMessage extends StatelessWidget {
  const _ConfirmedListMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.number, required this.user, this.onLeave});

  final String number;
  final RideUser user;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(
        number,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(user.motorcycleSnapshot ?? 'moto não informada'),
      trailing: onLeave == null
          ? InitialsAvatar(user.initials)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InitialsAvatar(user.initials),
                IconButton(
                  onPressed: onLeave,
                  color: AppColors.red,
                  tooltip: 'Sair da lista',
                  icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
                ),
              ],
            ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onShare,
    required this.onJoin,
    required this.joined,
  });

  final VoidCallback onShare;
  final VoidCallback? onJoin;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final background = joined ? AppColors.red : AppColors.green;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              label: const Text('Compartilhar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: onJoin,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                disabledBackgroundColor: background,
                disabledForegroundColor: AppColors.paper,
              ),
              child: Text(joined ? 'Sair da lista' : 'Eu vou'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet({required this.ride, required this.onContinue});

  final Ride ride;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Só falta dizer\nquem é você',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 34, height: 0.95),
          ),
          const SizedBox(height: 12),
          const Text('Entre com o Google pra entrar na lista. Leva um toque.'),
          const SizedBox(height: 18),
          _SmallRideTicket(ride: ride),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const FaIcon(FontAwesomeIcons.google),
              label: const Text('Continuar com o Google'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ver o feed e os rolês é livre. O login só aparece quando você se compromete.',
          ),
        ],
      ),
    );
  }
}

class _SmallRideTicket extends StatelessWidget {
  const _SmallRideTicket({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              ride.time,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ride.weekday} ${ride.date}'),
                  Text(
                    ride.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'saída: ${ride.departureName} · ${ride.confirmedCount} confirmados',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
