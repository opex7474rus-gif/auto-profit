import 'package:flutter/material.dart';

class AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Iterable<String> Function(String) optionsBuilder;
  final VoidCallback? onChangedCallback;

  const AutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.optionsBuilder,
    this.onChangedCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (tv) {
          final q = tv.text.trim();
          if (q.isEmpty) return const Iterable<String>.empty();
          return optionsBuilder(q);
        },
        onSelected: (value) {
          controller.text = value;
          onChangedCallback?.call();
        },
        fieldViewBuilder: (context, c, fn, onSubmitted) {
          return TextField(
            controller: c,
            focusNode: fn,
            onChanged: (_) => onChangedCallback?.call(),
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  c.clear();
                  onChangedCallback?.call();
                },
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 220, maxWidth: 320),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Text(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
