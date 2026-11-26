import 'package:flutter/material.dart';

class SearchSection extends StatelessWidget {
  const SearchSection({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.delete,
  });
  final TextEditingController searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? delete;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, _) {
          return TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher un client',
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: delete,
                    ),
              isDense: true,
            ),
          );
        },
      ),
    );
  }
}
