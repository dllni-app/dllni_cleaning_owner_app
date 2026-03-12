import 'dart:ui';

import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../features/orders/view/manager/bloc/orders_bloc.dart';
import '../../features/orders/domain/usecases/cancel_order_use_case.dart';

class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({super.key, required this.bloc, required this.orderId, required this.orderNum});

  final OrdersBloc bloc;
  final int orderId;
  final String orderNum;

  static Future<void> show(BuildContext context, {required OrdersBloc bloc, required int orderId, required String orderNum}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withAlpha(127),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => CancelOrderDialog(bloc: bloc, orderId: orderId, orderNum: orderNum),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onGoBack() {
    context.pop();
  }

  void _onCancelOrder() {
    widget.bloc.add(CancelOrderEvent(params: CancelOrderParams(id: widget.orderId), index: 0));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: const Color(0xFFE57373), borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomPaint(
                            size: const Size(40, 40),
                            painter: _WarningTrianglePainter(),
                            child: const Center(child: Icon(Icons.warning, color: Colors.white, size: 20)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'تحذير',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'cairo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'في حال قمت بإلغاء الطلب #${widget.orderNum} هذا سيترتب عليه ما يلي :',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'cairo', height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildConsequenceItem('1', 'خصم من نقاطك الثقة'),
                      const SizedBox(height: 8),
                      _buildConsequenceItem('2', 'زيادة معدل الإلغاء'),
                      const SizedBox(height: 8),
                      _buildConsequenceItem('3', 'نقصان معدل القبول'),
                      const SizedBox(height: 8),
                      _buildConsequenceItem(
                        '4',
                        'تأثير سلبي على ترتيب ظهورك في الطلبات القادمة. تكرار هذا السلوك قد يؤدي إلى تقييد مؤقت للحساب أو إيقافه كليا.',
                      ),
                      const SizedBox(height: 8),
                      _buildConsequenceItem('5', 'تنبيه إداري.'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _onGoBack,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: AppText.bodyLarge('تراجع', color: context.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _onCancelOrder,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: AppText.bodyLarge('إلغاء الطلب', color: context.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsequenceItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'cairo'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'cairo', height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _WarningTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
