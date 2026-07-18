import 'package:flutter/material.dart';

enum NotifyType { success, error, warning }

class AppNotify {
  /// Tampilkan popup notifikasi smooth (fade + scale), auto-dismiss 2.6 detik.
  static void show({
    required BuildContext context,
    required String message,
    required NotifyType type,
    Duration duration = const Duration(seconds: 2, milliseconds: 600),
  }) {
    final config = _config(type);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notification',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return _NotifyPopup(
          message: message,
          config: config,
          duration: duration,
          onClose: () => Navigator.of(ctx, rootNavigator: true).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void success(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifyType.success);

  static void error(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifyType.error);

  static void warning(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifyType.warning);
}

class _NotifyConfig {
  final Color color;
  final IconData icon;
  final String label;
  const _NotifyConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

_NotifyConfig _config(NotifyType type) {
  switch (type) {
    case NotifyType.success:
      return const _NotifyConfig(
        color: Color(0xFF2E7D32),
        icon: Icons.check_circle_rounded,
        label: 'Berhasil',
      );
    case NotifyType.error:
      return const _NotifyConfig(
        color: Color(0xFFC62828),
        icon: Icons.error_rounded,
        label: 'Gagal',
      );
    case NotifyType.warning:
      return const _NotifyConfig(
        color: Color(0xFFEF6C00),
        icon: Icons.warning_rounded,
        label: 'Perhatian',
      );
  }
}

class _NotifyPopup extends StatefulWidget {
  final String message;
  final _NotifyConfig config;
  final Duration duration;
  final VoidCallback onClose;

  const _NotifyPopup({
    required this.message,
    required this.config,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_NotifyPopup> createState() => _NotifyPopupState();
}

class _NotifyPopupState extends State<_NotifyPopup> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(c.icon, color: c.color, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                c.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
