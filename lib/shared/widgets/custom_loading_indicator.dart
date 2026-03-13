import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double width;
  final double height;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.width = 40,
    this.height = 30,
    this.color,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Calculate the phase for each bar to create a wave effect
              // The 5 bars are slightly offset in their animation phase
              final offset = index * 0.2;
              final t = (_controller.value + offset) % 1.0;
              
              // We want a smooth up and down wave. 
              // A sine wave shifted to be between 0 and 1 works well: (sin(t * 2 * pi) + 1) / 2
              // But to make it more like a bounce, we can use a varied scale
              double scale;
              if (t < 0.5) {
                // Going up
                scale = 0.3 + (t * 2 * 0.7);
              } else {
                // Going down
                scale = 1.0 - ((t - 0.5) * 2 * 0.7);
              }

              // Give a slight height variation to the middle bars to make it logo-like
              // Bar index: 0, 1, 2, 3, 4
              // Max scale multiplier: 0.6, 0.8, 1.0, 0.8, 0.6
              double maxScaleMult = 1.0;
              if (index == 0 || index == 4) maxScaleMult = 0.6;
              if (index == 1 || index == 3) maxScaleMult = 0.8;

              return Container(
                width: widget.width * 0.12,
                height: widget.height * (scale * maxScaleMult),
                decoration: BoxDecoration(
                  color: defaultColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
