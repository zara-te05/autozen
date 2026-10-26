import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Componente de entrada numérica defensiva (Principio de Menor Poder).
/// Impide que el usuario ingrese números negativos, caracteres inválidos
/// o valores fuera del rango permitido.
class SafeNumberPicker extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? label;
  final String? unit;
  final List<int>? quickSteps;

  const SafeNumberPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99999,
    this.step = 1,
    this.label,
    this.unit,
    this.quickSteps = const [1, 5, 10, 25],
  });

  @override
  State<SafeNumberPicker> createState() => _SafeNumberPickerState();
}

class _SafeNumberPickerState extends State<SafeNumberPicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant SafeNumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    _controller.text = clamped.toString();
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = widget.value > widget.min;
    final bool canIncrease = widget.value < widget.max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Rango: ${widget.min} - ${widget.max}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Stepper principal
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: canDecrease ? () => _updateValue(widget.value - widget.step) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.primary,
                disabledColor: Colors.black12,
                iconSize: 28,
                tooltip: 'Reducir ${widget.step}',
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (str) {
                          if (str.isEmpty) return;
                          final parsed = int.tryParse(str);
                          if (parsed != null) {
                            widget.onChanged(parsed.clamp(widget.min, widget.max));
                          }
                        },
                      ),
                    ),
                    if (widget.unit != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        widget.unit!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: canIncrease ? () => _updateValue(widget.value + widget.step) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primary,
                disabledColor: Colors.black12,
                iconSize: 28,
                tooltip: 'Aumentar ${widget.step}',
              ),
            ],
          ),
        ),

        // Chips de paso rápido si están habilitados
        if (widget.quickSteps != null && widget.quickSteps!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.quickSteps!.map((step) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text('+$step', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
                onPressed: () => _updateValue(widget.value + step),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
