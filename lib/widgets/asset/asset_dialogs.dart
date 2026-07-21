import 'package:flutter/material.dart';
import '../../models/asset_account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/center_toast.dart';
import '../../config/app_config.dart';
import '../common/app_number_field.dart';
import '../common/dialog_utils.dart';

// ─── Add Asset Sheet ───────────────────────────────────────

Future<String?> showAddAssetSheet(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => dialogFrame(
      context: ctx,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '添加资产',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _addOption(Icons.payments, Colors.teal, '现金', () {
            Navigator.pop(ctx, 'cash');
          }),
          _addOption(Icons.savings, Colors.orange, '定期存款', () {
            Navigator.pop(ctx, 'td');
          }),
          _addOption(Icons.trending_up, Colors.blueAccent, '理财/基金', () {
            Navigator.pop(ctx, 'wp');
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _addOption(
  IconData icon,
  Color color,
  String label,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    ),
    title: Text(
      label,
      style: const TextStyle(fontSize: 15, color: Colors.white),
    ),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ─── Cash Dialog ───────────────────────────────────────────

class _CashDialog extends StatefulWidget {
  final CashAccount? cash;
  final String defaultCurrency;
  final int assetCount;

  const _CashDialog({
    this.cash,
    required this.defaultCurrency,
    required this.assetCount,
  });

  @override
  State<_CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<_CashDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController balanceCtrl;
  late String currency;

  @override
  void initState() {
    super.initState();
    final cash = widget.cash;
    nameCtrl = TextEditingController(text: cash?.name ?? '');
    balanceCtrl = TextEditingController(
      text: cash != null ? CurrencyHelper.formatRate(cash.balance) : '',
    );
    currency = cash?.currency ?? widget.defaultCurrency;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cash != null;
    return dialogFrame(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              isEdit ? '编辑现金' : '添加现金',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('名称', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          _dialogTextField(nameCtrl, '例：活期账户、钱包'),
          const SizedBox(height: 12),
          const Text('余额', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppNumberField(
                  controller: balanceCtrl,
                  hintText: '0.00',
                ),
              ),
              const SizedBox(width: 8),
              _currencySelector(
                context,
                currency,
                (c) => setState(() => currency = c),
              ),
            ],
          ),
          const SizedBox(height: 20),
          actionButtonRow(
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              final balance = double.tryParse(balanceCtrl.text);
              if (balance == null || balance < 0) {
                CenterToast.error(context, '请输入有效金额');
                return;
              }
              final updated = CashAccount(
                id:
                    widget.cash?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                sortOrder: widget.cash?.sortOrder ?? widget.assetCount,
                currency: currency,
                name: nameCtrl.text.trim(),
                balance: balance,
                createdAt: widget.cash?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.pop(context, updated);
            },
            confirmText: isEdit ? DevConfig.btnClose : '添加',
            confirmGradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
            ),
          ),
        ],
      ),
    );
  }
}

Future<CashAccount?> showCashAssetDialog(
  BuildContext context, {
  CashAccount? cash,
  required String defaultCurrency,
  required int assetCount,
}) {
  return showDialog<CashAccount>(
    context: context,
    builder: (_) => _CashDialog(
      cash: cash,
      defaultCurrency: defaultCurrency,
      assetCount: assetCount,
    ),
  );
}

// ─── Time Deposit Dialog ───────────────────────────────────

class _TimeDepositDialog extends StatefulWidget {
  final TimeDeposit? td;
  final String defaultCurrency;
  final int assetCount;

  const _TimeDepositDialog({
    this.td,
    required this.defaultCurrency,
    required this.assetCount,
  });

  @override
  State<_TimeDepositDialog> createState() => _TimeDepositDialogState();
}

class _TimeDepositDialogState extends State<_TimeDepositDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController principalCtrl;
  late TextEditingController rateCtrl;
  late DateTime startDate;
  late int durationMonths;
  late String currency;

  @override
  void initState() {
    super.initState();
    final td = widget.td;
    nameCtrl = TextEditingController(text: td?.name ?? '');
    principalCtrl = TextEditingController(
      text: td != null ? CurrencyHelper.formatRate(td.principal) : '',
    );
    rateCtrl = TextEditingController(
      text: td != null ? td.annualRate.toString() : '',
    );
    startDate = td?.startDate ?? DateTime.now();
    durationMonths = td?.durationMonths ?? 12;
    currency = td?.currency ?? widget.defaultCurrency;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    principalCtrl.dispose();
    rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.td != null;
    return dialogFrame(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              isEdit ? '编辑定期存款' : '添加定期存款',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('名称'),
          const SizedBox(height: 6),
          _dialogTextField(nameCtrl, '例：一年定期'),
          const SizedBox(height: 12),
          const Text('本金', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppNumberField(
                  controller: principalCtrl,
                  hintText: '0.00',
                ),
              ),
              const SizedBox(width: 8),
              _currencySelector(
                context,
                currency,
                (c) => setState(() => currency = c),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '年利率 (%)',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          AppNumberField(controller: rateCtrl, hintText: '2.5'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _label('存入日期')),
              const SizedBox(width: 16),
              Expanded(child: _label('期限 (月)')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _dateButton(startDate, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF5B9CF6),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1A1F26),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => startDate = picked);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _durationSelector(
                  durationMonths,
                  (v) => setState(() => durationMonths = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          actionButtonRow(
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              final principal = double.tryParse(principalCtrl.text);
              final rate = double.tryParse(rateCtrl.text);
              if (principal == null || principal <= 0) {
                CenterToast.error(context, '请输入有效本金');
                return;
              }
              if (rate == null || rate < 0) {
                CenterToast.error(context, '请输入有效利率');
                return;
              }
              final updated = TimeDeposit(
                id:
                    widget.td?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                sortOrder: widget.td?.sortOrder ?? widget.assetCount,
                currency: currency,
                name: nameCtrl.text.trim(),
                principal: principal,
                annualRate: rate,
                startDate: startDate,
                durationMonths: durationMonths,
                createdAt: widget.td?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.pop(context, updated);
            },
            confirmText: isEdit ? DevConfig.btnClose : '添加',
            confirmGradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
            ),
          ),
        ],
      ),
    );
  }
}

Future<TimeDeposit?> showTimeDepositDialog(
  BuildContext context, {
  TimeDeposit? td,
  required String defaultCurrency,
  required int assetCount,
}) {
  return showDialog<TimeDeposit>(
    context: context,
    builder: (_) => _TimeDepositDialog(
      td: td,
      defaultCurrency: defaultCurrency,
      assetCount: assetCount,
    ),
  );
}

// ─── Wealth Product Dialog ─────────────────────────────────

class _WealthProductDialog extends StatefulWidget {
  final WealthProduct? wp;
  final String defaultCurrency;
  final int assetCount;

  const _WealthProductDialog({
    this.wp,
    required this.defaultCurrency,
    required this.assetCount,
  });

  @override
  State<_WealthProductDialog> createState() => _WealthProductDialogState();
}

class _WealthProductDialogState extends State<_WealthProductDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController sharesCtrl;
  late TextEditingController navCtrl;
  late String currency;

  @override
  void initState() {
    super.initState();
    final wp = widget.wp;
    nameCtrl = TextEditingController(text: wp?.name ?? '');
    sharesCtrl = TextEditingController(
      text: wp != null ? CurrencyHelper.formatRate(wp.shares) : '',
    );
    navCtrl = TextEditingController(
      text: wp != null ? CurrencyHelper.formatRate(wp.nav) : '',
    );
    currency = wp?.currency ?? widget.defaultCurrency;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    sharesCtrl.dispose();
    navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wp != null;
    return dialogFrame(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              isEdit ? '编辑理财/基金' : '添加理财/基金',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('名称'),
          const SizedBox(height: 6),
          _dialogTextField(nameCtrl, '例：余额宝、某某基金'),
          const SizedBox(height: 12),
          const Text(
            '持有份额',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          AppNumberField(controller: sharesCtrl, hintText: '0.00'),
          const SizedBox(height: 12),
          const Text(
            '最新净值',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppNumberField(controller: navCtrl, hintText: '1.0000'),
              ),
              const SizedBox(width: 8),
              _currencySelector(
                context,
                currency,
                (c) => setState(() => currency = c),
              ),
            ],
          ),
          const SizedBox(height: 20),
          actionButtonRow(
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              final shares = double.tryParse(sharesCtrl.text);
              final nav = double.tryParse(navCtrl.text);
              if (shares == null || shares <= 0) {
                CenterToast.error(context, '请输入有效份额');
                return;
              }
              if (nav == null || nav <= 0) {
                CenterToast.error(context, '请输入有效净值');
                return;
              }
              final updated = WealthProduct(
                id:
                    widget.wp?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                sortOrder: widget.wp?.sortOrder ?? widget.assetCount,
                currency: currency,
                name: nameCtrl.text.trim(),
                shares: shares,
                nav: nav,
                createdAt: widget.wp?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.pop(context, updated);
            },
            confirmText: isEdit ? DevConfig.btnClose : '添加',
            confirmGradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
            ),
          ),
        ],
      ),
    );
  }
}

Future<WealthProduct?> showWealthProductDialog(
  BuildContext context, {
  WealthProduct? wp,
  required String defaultCurrency,
  required int assetCount,
}) {
  return showDialog<WealthProduct>(
    context: context,
    builder: (_) => _WealthProductDialog(
      wp: wp,
      defaultCurrency: defaultCurrency,
      assetCount: assetCount,
    ),
  );
}

// ─── Shared Form Widgets ───────────────────────────────────

Widget _label(String text) {
  return Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey));
}

Widget _dialogTextField(TextEditingController ctrl, String hint) {
  return TextField(
    controller: ctrl,
    keyboardType: TextInputType.text,
    style: const TextStyle(fontSize: 16, color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF161B22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303631)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303631)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
  );
}

Widget _currencySelector(
  BuildContext context,
  String selected,
  ValueChanged<String> onChanged,
) {
  final currencies = CurrencyHelper.exchangeRates.keys.toList();
  return Builder(
    builder: (btnCtx) {
      return GestureDetector(
        onTap: () async {
          final RenderBox button = btnCtx.findRenderObject() as RenderBox;
          final overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final result = await showMenu<String>(
            context: context,
            position: RelativeRect.fromRect(
              button.localToGlobal(Offset.zero, ancestor: overlay) &
                  button.size,
              Offset.zero & overlay.size,
            ),
            color: const Color(0xFF1A1F26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF303631)),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            items: currencies.map((c) {
              final isSel = c == selected;
              return PopupMenuItem<String>(
                value: c,
                height: 36,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: isSel
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFF5B9CF6),
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c,
                      style: TextStyle(
                        color: isSel ? const Color(0xFF5B9CF6) : Colors.white,
                        fontSize: 14,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
          if (result != null) onChanged(result);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF303631)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, color: Colors.grey, size: 20),
            ],
          ),
        ),
      );
    },
  );
}

Widget _dateButton(DateTime date, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Row(
        children: [
          Text(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const Spacer(),
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        ],
      ),
    ),
  );
}

Widget _durationSelector(int selected, ValueChanged<int> onChanged) {
  const options = [1, 3, 6, 12, 24, 36, 60];
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF303631)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: selected,
        dropdownColor: const Color(0xFF1A1F26),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: options
            .map((m) => DropdownMenuItem(value: m, child: Text('${m}个月')))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}
