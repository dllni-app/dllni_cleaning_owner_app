import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/supervised_worker_booking.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/emergency_sos_screen.dart';
import 'package:flutter/material.dart';
import 'worker_booking_inventory_card.dart';
import 'worker_detail_section.dart';

/// Read-only team view. No worker lifecycle or material controls are mounted.
class SupervisedWorkerDetailsBody extends StatefulWidget {
  const SupervisedWorkerDetailsBody({
    super.key,
    required this.bookingId,
    required this.onBack,
    this.refreshRevision = 0,
  });

  final int bookingId;
  final VoidCallback onBack;
  final int refreshRevision;

  @override
  State<SupervisedWorkerDetailsBody> createState() =>
      _SupervisedWorkerDetailsBodyState();
}

class _SupervisedWorkerDetailsBodyState
    extends State<SupervisedWorkerDetailsBody> {
  late Future<SupervisedWorkerBooking> _booking;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant SupervisedWorkerDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookingId != oldWidget.bookingId ||
        widget.refreshRevision != oldWidget.refreshRevision) {
      _reload();
    }
  }

  void _reload() {
    _booking = getIt<OrdersRemoteDataSource>().fetchSupervisedBooking(
      widget.bookingId,
    );
  }

  void _refresh() => setState(_reload);

  Widget _section(String title, List<Widget> children) {
    return WorkerDetailSection(title: title, children: children);
  }

  Widget _detailLine(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: 'رجوع',
                  icon: const Icon(Icons.arrow_forward),
                ),
                const Expanded(
                  child: Text(
                    'تفاصيل مهمتي',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'تحديث الطلب',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<SupervisedWorkerBooking>(
              future: _booking,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تعذر تحميل الطلب. قد يكون التكليف قد تغير أو انقطع الاتصال.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final booking = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    _refresh();
                    try {
                      await _booking;
                    } catch (_) {
                      /* Render retry. */
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _section('ملخص المهمة', [
                        _detailLine(
                          Icons.groups_outlined,
                          'طلب جماعي بإدارة مشرف',
                        ),
                        _detailLine(
                          Icons.receipt_long_outlined,
                          'المرجع: ${booking.bookingNumber}',
                        ),
                        if (booking.scheduledDate != null)
                          _detailLine(
                            Icons.calendar_today_outlined,
                            '${booking.scheduledDate}   ${booking.scheduledTime ?? ''}',
                          ),
                        if (booking.neighborhoodName?.isNotEmpty == true)
                          _detailLine(
                            Icons.place_outlined,
                            booking.neighborhoodName!,
                          ),
                        if (booking.supervisorName?.isNotEmpty == true)
                          _detailLine(
                            Icons.person_outline,
                            'المشرف: ${booking.supervisorName}',
                          ),
                        _detailLine(
                          Icons.info_outline,
                          'الحالة: ${_status(booking.status)}',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'المشرف مسؤول عن الحضور والانطلاق وبدء التنفيذ والاستلام.',
                        ),
                      ]),
                      if (booking.propertyDetails['customService']
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true)
                        _section('طبيعة الخدمة المطلوبة', [
                          Text(
                            booking.propertyDetails['customService'].toString(),
                          ),
                          if (booking.propertyDetails['hours'] != null)
                            _detailLine(
                              Icons.access_time,
                              'المدة: ${booking.propertyDetails['hours']} ساعة',
                            ),
                        ]),
                      _section(
                        'مهامي المطلوبة',
                        booking.tasks.isEmpty
                            ? [const Text('لم تتوفر تفاصيل مهام التنظيف بعد.')]
                            : booking.tasks.map((task) {
                                final title = task['title']?.toString().trim();
                                final size = task['roomSize']
                                    ?.toString()
                                    .trim();
                                final mode = task['cleaningMode']?.toString();
                                final modeLabel = mode == 'deep'
                                    ? 'تعزيل'
                                    : mode == 'regular'
                                    ? 'حوسة'
                                    : null;
                                final note = task['notes']?.toString().trim();
                                return _detailLine(
                                  Icons.checklist_outlined,
                                  '${title?.isNotEmpty == true ? title : 'غرفة'}'
                                  '${size?.isNotEmpty == true ? ' · $size' : ''}'
                                  '${modeLabel != null ? ' · $modeLabel' : ''}'
                                  '${note?.isNotEmpty == true ? ' · $note' : ''}',
                                );
                              }).toList(),
                      ),
                      _section(
                        'الخدمات المتخصصة',
                        booking.specializedServices.isEmpty
                            ? [const Text('لا توجد خدمات متخصصة في هذا الطلب.')]
                            : booking.specializedServices.map((service) {
                                final name =
                                    service['name']?.toString() ??
                                    'خدمة متخصصة';
                                final quantity =
                                    service['quantity']?.toString() ?? '1';
                                final notes = service['notes']?.toString();
                                final severity = service['dirtinessLevel']
                                    ?.toString();
                                final description = [
                                  '$name × $quantity',
                                  if (severity == 'light') 'اتساخ بسيط',
                                  if (severity == 'heavy') 'اتساخ شديد',
                                  if (notes?.trim().isNotEmpty == true)
                                    notes!.trim(),
                                ].join(' · ');
                                return _detailLine(
                                  Icons.cleaning_services_outlined,
                                  description,
                                );
                              }).toList(),
                      ),
                      WorkerBookingInventoryCard(bookingId: widget.bookingId),
                      if (booking.allowedActions.contains('sos'))
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sos_outlined),
                          label: const Text('الإبلاغ عن حالة طارئة'),
                          onPressed: () => Navigator.of(context).pushNamed(
                            '/emergencysos',
                            arguments: EmergencySosScreenParams(
                              bookingId: widget.bookingId,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _status(String status) => switch (status) {
    'pending' => 'بانتظار تجهيز الفريق',
    'worker_assigned' => 'الفريق جاهز',
    'in_progress' => 'قيد التنفيذ',
    'awaiting_customer_completion' => 'بانتظار تأكيد العميل',
    'completed' => 'مكتمل',
    'cancelled' => 'ملغى',
    'under_dispute' => 'قيد المراجعة',
    _ => 'قيد المتابعة',
  };
}
