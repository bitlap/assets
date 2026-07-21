import 'package:flutter/material.dart';
import '../../config/app_config.dart';

Color get _bg => const Color(0xFF0C1117);
Color get _borderColor => const Color(0xFF303631);

BorderRadius _radius20 = BorderRadius.circular(20);
BorderRadius _radius12 = BorderRadius.circular(12);

BoxDecoration dialogFrameDecoration({
  BorderRadius? borderRadius,
  Color? bgColor,
  Color? borderColor,
  EdgeInsets? padding,
}) {
  return BoxDecoration(
    borderRadius: borderRadius ?? _radius20,
    border: Border.all(color: borderColor ?? _borderColor),
    color: bgColor,
  );
}

Widget dialogFrame({
  required BuildContext context,
  required Widget child,
  Color? bgColor,
  BorderRadius? borderRadius,
  EdgeInsets? insetPadding,
  Color? borderColor,
  EdgeInsets? padding,
  double? widthRatio,
}) {
  final view = View.of(context);
  final pixRatio = view.devicePixelRatio;
  final bottomInset = view.viewInsets.bottom / pixRatio;
  final screenHeight = view.physicalSize.height / pixRatio;
  final vInset = (insetPadding?.vertical ?? 48);
  final vPad = (padding?.vertical ?? 40);
  final maxContentHeight = screenHeight - bottomInset - vInset - vPad - 16;

  return Dialog(
    backgroundColor: bgColor ?? _bg,
    shape: RoundedRectangleBorder(borderRadius: borderRadius ?? _radius20),
    insetPadding:
        insetPadding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: SizedBox(
      width:
          MediaQuery.of(context).size.width *
          (widthRatio ?? DevConfig.dialogWidthRatio),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: dialogFrameDecoration(
          borderRadius: borderRadius,
          bgColor: bgColor,
          borderColor: borderColor,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxContentHeight),
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

Widget cancelButton({required VoidCallback onTap, String? text}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: _radius12,
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Text(
          text ?? DevConfig.btnCancel,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

Widget confirmButton({
  required VoidCallback onTap,
  required String text,
  Color? bgColor,
  Gradient? gradient,
}) {
  assert(bgColor != null || gradient != null);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: _radius12,
        color: bgColor,
        gradient: gradient,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

Widget actionButtonRow({
  required VoidCallback onCancel,
  required VoidCallback onConfirm,
  required String confirmText,
  Color? confirmBgColor,
  Gradient? confirmGradient,
  String? cancelText,
}) {
  return Row(
    children: [
      Expanded(
        child: cancelButton(onTap: onCancel, text: cancelText),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: confirmButton(
          onTap: onConfirm,
          text: confirmText,
          bgColor: confirmBgColor,
          gradient: confirmGradient,
        ),
      ),
    ],
  );
}

class DialogInfoTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  const DialogInfoTitle({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFF5B9CF6)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}

class InfoDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final String? closeText;
  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.closeText,
  });

  static Future<void> show(
    BuildContext context, {
    required Widget title,
    required Widget content,
    String? closeText,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          InfoDialog(title: title, content: content, closeText: closeText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            closeText ?? DevConfig.btnClose,
            style: const TextStyle(color: Color(0xFF5B9CF6)),
          ),
        ),
      ],
    );
  }
}

class HintRow extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;
  const HintRow({
    super.key,
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label：',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
