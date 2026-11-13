import 'package:flutter/material.dart';

import '../models/cities.dart';

/// Окно выбора города. Возвращает выбранный город или null.
Future<String?> pickCity(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Выберите город',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(city),
                      trailing: city == current
                          ? const Icon(Icons.check_circle)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(city),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
