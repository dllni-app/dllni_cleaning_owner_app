from pathlib import Path

path = Path('lib/features/orders/view/widgets/accept_order_bottom_sheet.dart')
text = path.read_text()

old = """          child: AppText.bodySmall(\n            'يمكنك قبول جميع الجلسات، أو تحديد الجلسات التي تستطيع تنفيذها فقط. الجلسات التي لا تقبلها تبقى متاحة لعمال مؤهلين آخرين.',\n            fontWeight: FontWeight.w800,\n            color: const Color(0xff1E3A8A),\n            textAlign: TextAlign.start,\n          ),\n"""
new = """          child: AppText.bodySmall(\n            _isEventAssistance\n                ? 'هذه المناسبة تتطلب الالتزام بجميع الأيام. لن يتم قبول الطلب إذا كان لديك تعارض في أي يوم.'\n                : 'يمكنك قبول جميع الجلسات، أو تحديد الجلسات التي تستطيع تنفيذها فقط. الجلسات التي لا تقبلها تبقى متاحة لعمال مؤهلين آخرين.',\n            fontWeight: FontWeight.w800,\n            color: const Color(0xff1E3A8A),\n            textAlign: TextAlign.start,\n          ),\n"""
if old not in text:
    raise SystemExit('schedule phase-one copy pattern not found')
text = text.replace(old, new, 1)

old = """                          AppText.bodySmall(\n                            _isMultiSession\n                                ? 'راجع جميع الجلسات وحدد نطاق التزامك قبل القبول'\n                                : 'يرجى تأكيد تفاصيل الطلب قبل القبول',\n                            color: _mutedTextColor,\n                            textAlign: TextAlign.start,\n                          ),\n"""
new = """                          AppText.bodySmall(\n                            _isEventAssistance && _isMultiSession\n                                ? 'راجع جميع أيام المناسبة؛ القبول يعني الالتزام بها جميعاً'\n                                : _isMultiSession\n                                ? 'راجع جميع الجلسات وحدد نطاق التزامك قبل القبول'\n                                : 'يرجى تأكيد تفاصيل الطلب قبل القبول',\n                            color: _mutedTextColor,\n                            textAlign: TextAlign.start,\n                          ),\n"""
if old not in text:
    raise SystemExit('header phase-one copy pattern not found')
text = text.replace(old, new, 1)

old = """                          const SizedBox(height: 10),\n                          SizedBox(\n                            width: double.infinity,\n                            child: OutlinedButton.icon(\n                              onPressed: accepting || !_canConfirmAcceptance\n                                  ? null\n                                  : _showSelectedSessionsPicker,\n                              icon: const Icon(Icons.checklist_rtl),\n                              label: const Text(\n                                'تحديد الجلسات التي يمكنني قبولها',\n                              ),\n                            ),\n                          ),\n"""
new = """                          if (!_isEventAssistance) ...[\n                            const SizedBox(height: 10),\n                            SizedBox(\n                              width: double.infinity,\n                              child: OutlinedButton.icon(\n                                onPressed: accepting || !_canConfirmAcceptance\n                                    ? null\n                                    : _showSelectedSessionsPicker,\n                                icon: const Icon(Icons.checklist_rtl),\n                                label: const Text(\n                                  'تحديد الجلسات التي يمكنني قبولها',\n                                ),\n                              ),\n                            ),\n                          ],\n"""
if old not in text:
    raise SystemExit('partial acceptance button pattern not found')
text = text.replace(old, new, 1)

old = """                                      : const Text('قبول جميع الجلسات'),\n"""
new = """                                      : Text(\n                                          _isEventAssistance\n                                              ? 'قبول جميع أيام المناسبة'\n                                              : 'قبول جميع الجلسات',\n                                        ),\n"""
if old not in text:
    raise SystemExit('accept all label pattern not found')
text = text.replace(old, new, 1)

path.write_text(text)
