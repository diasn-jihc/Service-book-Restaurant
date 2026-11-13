import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../blocs/data_cubit.dart';
import '../../services/report_service.dart';
import '../../utils/actions.dart';
import '../../widgets/app_card.dart';

/// Отчёт за день: можно скопировать или сохранить в файл.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    final text = buildDayReport(context.repo, restaurantId);

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт за день')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(child: SelectableText(text)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) showMessage(context, 'Скопировано');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Копировать'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final path = await saveReportFile(text);
                    if (!context.mounted) return;
                    showMessage(context,
                        path == null ? 'В веб-версии файл не сохраняется' : 'Сохранено: $path');
                  },
                  icon: const Icon(Icons.save_alt),
                  label: const Text('В файл'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
