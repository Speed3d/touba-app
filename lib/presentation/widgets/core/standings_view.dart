import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/team_model.dart';

/// 📝 HINT AR: جدول الترتيب المشترك (الوجبة 7) — واعٍ بالمجموعات: إن حملت الصفوف
/// حقل group يعرض جدولاً لكل مجموعة بعنوانها، وإلا جدولاً واحداً (الدوري).
class StandingsView extends StatelessWidget {
  final List<dynamic> standings;
  final Map<String, TeamModel> teamsById;
  const StandingsView({
    super.key,
    required this.standings,
    required this.teamsById,
  });

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('سيظهر الترتيب بعد إدخال أول نتيجة',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }
    final rows = standings.map((e) => Map<String, dynamic>.from(e)).toList();
    final hasGroups = rows.any((r) => (r['group'] ?? '').toString().isNotEmpty);

    if (!hasGroups) {
      return _table(context, rows);
    }
    // تجميع حسب المجموعة وفرز كل مجموعة.
    final byGroup = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      byGroup.putIfAbsent((r['group'] ?? '').toString(), () => []).add(r);
    }
    final groups = byGroup.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6, right: 4),
            child: Text('المجموعة $g',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          _table(context, byGroup[g]!),
        ],
      ],
    );
  }

  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('الفريق')),
            DataColumn(label: Text('ل')),
            DataColumn(label: Text('ف')),
            DataColumn(label: Text('ت')),
            DataColumn(label: Text('خ')),
            DataColumn(label: Text('±')),
            DataColumn(label: Text('نقاط')),
          ],
          rows: List.generate(rows.length, (i) {
            final s = rows[i];
            final team = teamsById[s['teamId']];
            return DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logo(team?.logoUrl),
                  const SizedBox(width: 6),
                  Text(team?.name ?? '—'),
                ],
              )),
              DataCell(Text('${s['played'] ?? 0}')),
              DataCell(Text('${s['won'] ?? 0}')),
              DataCell(Text('${s['drawn'] ?? 0}')),
              DataCell(Text('${s['lost'] ?? 0}')),
              DataCell(Text('${s['gd'] ?? 0}')),
              DataCell(Text('${s['points'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _logo(String? url) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: (url != null && url.isNotEmpty)
          ? CachedNetworkImageProvider(url)
          : null,
      child: (url == null || url.isEmpty)
          ? Icon(Icons.shield, size: 12, color: Colors.grey.shade400)
          : null,
    );
  }
}
