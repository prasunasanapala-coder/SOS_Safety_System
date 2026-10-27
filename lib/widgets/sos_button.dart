import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large pulsing SOS button (Experiments 2b, 6a and 8).
///
/// Layout: a [Stack] puts an animated halo behind the button. Animation: one
/// repeating [AnimationController] drives the halo's scale/fade and a slight
/// scale of the button itself.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onPressed,
    this.size = 180,
    this.label = 'SOS',
  });

  final VoidCallback? onPressed;
  final double size;
  final String label;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion || widget.onPressed == null) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: 'Start SOS alert countdown',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size * 1.35,
          height: size * 1.35,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = _pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Halo ring
                  Transform.scale(
                    scale: 1 + 0.3 * t,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sos.withValues(alpha: 0.22 * (1 - t)),
                      ),
                    ),
                  ),
                  Transform.scale(scale: 1 + 0.03 * t, child: child),
                ],
              );
            },
            child: Material(
              color: AppColors.sos,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                key: const Key('sos_button'),
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 44),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}