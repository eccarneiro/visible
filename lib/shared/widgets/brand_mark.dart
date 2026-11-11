import 'package:flutter/material.dart';

/// Marca do app: ícone em bloco + nome "Visible".
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(size * .28),
          ),
          child: Icon(Icons.visibility_outlined,
              color: cs.onPrimary, size: size * .6),
        ),
        SizedBox(width: size * .35),
        Text('Visible',
            style: TextStyle(
                fontSize: size * .68,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
                color: cs.onSurface)),
      ],
    );
  }
}
