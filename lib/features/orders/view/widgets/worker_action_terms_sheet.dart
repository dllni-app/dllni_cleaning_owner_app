import 'package:flutter/material.dart';

/// Financial charges are computed by the server, never in the app.
Future<bool> confirmWorkerActionTerms(
  BuildContext context, {
  required bool cancelling,
  num? cancellationPenaltyAmount,
  String currency = 'ل.س',
}) async {
  var accepted = false;
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setLocalState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      cancelling ? 'شروط إلغاء الزيارة' : 'شروط قبول الطلب',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cancelling
                          ? 'عند إلغاء زيارة سبق قبولها، يعود المقعد متاحاً لإسناد عامل بديل، وقد تتأثر نقاط الثقة. بحسب نوع الطلب ومسار الإلغاء، قد تُسجَّل غرامة مالية وفق إعدادات النظام الحالية دون اشتراط مرور 24 ساعة على القبول. لا يمكن إلغاء الزيارة بعد بدء التوجّه، ويلزم توضيح سبب الإلغاء.'
                          : 'أتعهد بالحضور في الموعد المحدد، وتنفيذ الخدمات المتفق عليها بعناية ومهنية، والمحافظة على ممتلكات العميل وأغراضه وعدم استخدامها أو نقلها دون إذن. ألتزم بخصوصية العميل وإبلاغ الدعم فور حدوث أي تلف أو حادث أو تعذر عن تنفيذ العمل.',
                      textAlign: TextAlign.right,
                    ),
                    if (cancelling &&
                        cancellationPenaltyAmount != null &&
                        cancellationPenaltyAmount > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'قيمة الغرامة المالية المضبوطة حالياً في النظام: ${cancellationPenaltyAmount.toStringAsFixed(0)} $currency. لا يعني عرضها أنها خُصمت مسبقاً.',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: accepted,
                      onChanged: (value) =>
                          setLocalState(() => accepted = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'قرأت الشروط والأحكام وفهمت آثار هذا الإجراء وأوافق عليها',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: accepted
                          ? () => Navigator.of(sheetContext).pop(true)
                          : null,
                      child: Text(
                        cancelling
                            ? 'المتابعة إلى سبب الإلغاء'
                            : 'تأكيد قبول الطلب',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ) ??
      false;
}
