import 'package:flutter/material.dart';
import '../../models/viaggio.dart';
import 'diary_card.dart';

class AnimatedDiaryCard extends StatefulWidget {
  final Viaggio viaggio;
  final int index;

  // Aggiungiamo i callback opzionali per delete e tap
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const AnimatedDiaryCard({
    super.key,
    required this.viaggio,
    required this.index,
    this.onDelete,
    this.onTap,
  });

  @override
  State<AnimatedDiaryCard> createState() => _AnimatedDiaryCardState();
}

class _AnimatedDiaryCardState extends State<AnimatedDiaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: DiaryCard(
          viaggio: widget.viaggio,
          onDelete: widget.onDelete,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

