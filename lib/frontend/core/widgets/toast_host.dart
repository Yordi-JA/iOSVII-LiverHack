import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class Toast {
  const Toast(this.id, this.message);

  final int id;

  /// Texto con fragmentos en **negritas**.
  final String message;
}

class ToastNotifier extends Notifier<Toast?> {
  var _next = 0;

  @override
  Toast? build() => null;

  void show(String message) => state = Toast(_next++, message);

  void dismiss() => state = null;
}

final toastProvider = NotifierProvider<ToastNotifier, Toast?>(ToastNotifier.new);

/// Cápsula de vidrio inferior centrada que muestra el último toast durante 3.8 s.
class ToastHost extends ConsumerStatefulWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends ConsumerState<ToastHost> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(toastProvider, (_, next) {
      _timer?.cancel();
      if (next != null) _timer = Timer(const Duration(milliseconds: 3800), ref.read(toastProvider.notifier).dismiss);
    });
    final toast = ref.watch(toastProvider);

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 16,
          right: 16,
          bottom: 28,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              child: toast == null
                  ? const SizedBox.shrink()
                  : _ToastCapsule(key: ValueKey(toast.id), message: toast.message),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCapsule extends StatelessWidget {
  const _ToastCapsule({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final parts = message.split('**');
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        TextSpan(
                          text: parts[i],
                          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
