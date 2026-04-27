import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TenteSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const TenteSectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class TenteRowLabel extends StatelessWidget {
  final String text;

  const TenteRowLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TenteColorChipsEditor extends StatelessWidget {
  final List<String> colorsHex;
  final void Function(String hex) onAdd;
  final void Function(String hex) onRemove;

  const TenteColorChipsEditor({
    super.key,
    required this.colorsHex,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        ...colorsHex.map((hex) {
          final color = _parseHexColor(hex);
          return Chip(
            label: Text(
              hex.toUpperCase(),
              style: TextStyle(
                color:
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: color,
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => onRemove(hex),
          );
        }),
        _AddColorButton(
          onPick: (color) {
            final hex = _toHex(color);
            if (!colorsHex.contains(hex)) {
              onAdd(hex);
            }
          },
        ),
      ],
    );
  }

  static Color _parseHexColor(String hex) {
    try {
      final h = hex.startsWith('#') ? hex.substring(1) : hex;
      return Color(int.parse(h, radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.grey.shade400;
    }
  }

  static String _toHex(Color color) {
    final value = (color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return '#$value';
  }
}

class _AddColorButton extends StatelessWidget {
  final void Function(Color) onPick;

  const _AddColorButton({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        Color temp = Colors.blue;
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choisir une couleur'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: temp,
                onColorChanged: (color) => temp = color,
                enableAlpha: false,
                pickerAreaHeightPercent: 0.7,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Ajouter'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        if (ok == true) {
          onPick(temp);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(19),
          color: Colors.white,
        ),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }
}
