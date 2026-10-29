import 'package:flutter/material.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_v2_replacement_offer.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';

/// Offers are scoped by the server to the logged-in worker. A worker is never
/// obliged to accept other visits and acceptance does not assign work itself.
abstract class WorkerV2ReplacementOffersGateway {
  Future<List<WorkerV2ReplacementOffer>> fetch();

  Future<bool> accept(WorkerV2ReplacementOffer offer);
}

class _LiveWorkerV2ReplacementOffersGateway
    implements WorkerV2ReplacementOffersGateway {
  OrdersRemoteDataSource get _api => getIt<OrdersRemoteDataSource>();

  @override
  Future<List<WorkerV2ReplacementOffer>> fetch() =>
      _api.fetchV2ReplacementOffers();

  @override
  Future<bool> accept(WorkerV2ReplacementOffer offer) =>
      _api.acceptV2ReplacementOffer(
        bookingId: offer.bookingId,
        visitSequence: offer.visitSequence,
        requestId: offer.requestId,
      );
}

class WorkerV2ReplacementOffersCard extends StatefulWidget {
  const WorkerV2ReplacementOffersCard({super.key, this.gateway});

  final WorkerV2ReplacementOffersGateway? gateway;

  @override
  State<WorkerV2ReplacementOffersCard> createState() =>
      _WorkerV2ReplacementOffersCardState();
}

class _WorkerV2ReplacementOffersCardState
    extends State<WorkerV2ReplacementOffersCard> {
  late final WorkerV2ReplacementOffersGateway _gateway =
      widget.gateway ?? _LiveWorkerV2ReplacementOffersGateway();
  List<WorkerV2ReplacementOffer> _offers = const [];
  bool _loading = false;
  bool _accepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading || _accepting) return;
    setState(() => _loading = true);
    try {
      final offers = await _gateway.fetch();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر تحديث عروض الزيارات البديلة.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(WorkerV2ReplacementOffer offer) async {
    if (_accepting || _loading) return;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قبول زيارة بديلة'),
        content: Text(
          'هل تريد قبول الزيارة رقم ${offer.visitSequence}؟ '
          'قبول هذه الزيارة لا يعني قبول أي زيارة أخرى، ولا يبدأ العمل أو التسوية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ليس الآن'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('أوافق على هذه الزيارة'),
          ),
        ],
      ),
    );
    if (!mounted || answer != true) return;
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      final accepted = await _gateway.accept(offer);
      if (!mounted) return;
      if (!accepted) {
        setState(() => _error = 'لم يتم قبول الزيارة. حاول مجدداً.');
        return;
      }
      setState(
        () => _offers = _offers
            .where((item) => item.requestId != offer.requestId)
            .toList(growable: false),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تسجيل قبولك، بانتظار إكمال إسناد الزيارة من المشرف.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر قبول العرض، قد يكون انتهت صلاحيته.');
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_offers.isEmpty && _error == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'عروض زيارات بديلة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('كل زيارة قرار مستقل، ويمكنك عدم قبول العرض.'),
            if (_loading || _accepting) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _loading || _accepting ? null : _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
            for (final offer in _offers) ...[
              const Divider(),
              Text(
                'الزيارة ${offer.visitSequence} — ${offer.scheduledDate} ${offer.scheduledTime}',
              ),
              Text('رقم الطلب: ${offer.bookingId}'),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  key: Key('v2-accept-replacement-${offer.requestId}'),
                  onPressed: _loading || _accepting
                      ? null
                      : () => _accept(offer),
                  child: const Text('قبول هذه الزيارة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
