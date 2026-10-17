import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_inventory.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';
import 'package:flutter/material.dart';

/// Assigned materials/equipment are read from the authenticated inventory API;
/// customer material prices and other workers' stock are never exposed here.
class WorkerBookingInventoryCard extends StatefulWidget {
  const WorkerBookingInventoryCard({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<WorkerBookingInventoryCard> createState() =>
      _WorkerBookingInventoryCardState();
}

class _WorkerBookingInventoryCardState
    extends State<WorkerBookingInventoryCard> {
  late Future<WorkerBookingInventory> _inventory;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant WorkerBookingInventoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingId != widget.bookingId) _reload();
  }

  void _reload() {
    _inventory = getIt<OrdersRemoteDataSource>().fetchBookingInventory(
      widget.bookingId,
    );
  }

  void _retry() => setState(_reload);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: FutureBuilder<WorkerBookingInventory>(
          future: _inventory,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تعذّر تحميل عهدة المعدات والمواد لهذا الطلب.',
                      ),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }
            final kit = snapshot.data!;
            if (kit.materials.isEmpty && kit.equipment.isEmpty) {
              return const ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('عهدة المواد والمعدات'),
                subtitle: Text(
                  'لا توجد معدات أو مواد مُسلّمة إليك في هذا الطلب.',
                ),
              );
            }

            return ExpansionTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('المواد والمعدات المستلمة'),
              subtitle: Text(
                'مواد: ${kit.materials.length} · معدات: ${kit.equipment.length}',
              ),
              children: [
                if (kit.materials.isNotEmpty) ...[
                  const ListTile(title: Text('مواد تنظيف استهلاكية')),
                  for (final line in kit.materials)
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: Text(line.name),
                      subtitle: Text('الحالة: ${line.statusAr}'),
                      trailing: Text(
                        '${line.quantity ?? 0} ${line.unit ?? ''}',
                      ),
                    ),
                ],
                if (kit.equipment.isNotEmpty) ...[
                  const ListTile(title: Text('معدات مستعارة يجب إرجاعها')),
                  for (final line in kit.equipment)
                    ListTile(
                      leading: const Icon(Icons.handyman_outlined),
                      title: Text(line.name),
                      subtitle: Text('الحالة: ${line.statusAr}'),
                      trailing: Text(line.assetCode ?? ''),
                    ),
                ],
                TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث عهدة الطلب'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
