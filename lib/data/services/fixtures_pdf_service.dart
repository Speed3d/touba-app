import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';

/// 📝 HINT AR: توليد تقرير PDF لجدول البطولة (بند 6) — كل المباريات بجولاتها
/// وتواريخها وأوقاتها والحكّام، ليشاركه المنظّم مع كباتن الفرق. يستخدم خطّ
/// عربيّ (Cairo) مع اتجاه RTL ليظهر النص العربي صحيحاً.
class FixturesPdfService {
  static Future<void> shareTournamentSchedule({
    required TournamentModel tournament,
    required List<MatchModel> matches,
  }) async {
    final doc = pw.Document();
    final base = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    // 📝 HINT AR: تجميع المباريات بالجولة + ترتيبها.
    final byRound = <int, List<MatchModel>>{};
    for (final m in matches) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();

    String dateStr(DateTime? dt) =>
        dt == null ? 'غير محدد' : DateFormat('yyyy/MM/dd', 'ar').format(dt);
    String timeStr(DateTime? dt) =>
        dt == null ? '—' : DateFormat('HH:mm').format(dt);

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Center(
            child: pw.Text('جدول بطولة ${tournament.name}',
                style: pw.TextStyle(font: bold, fontSize: 22)),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
                'المدينة: ${tournament.city}  •  عدد المباريات: ${matches.length}',
                style: pw.TextStyle(font: base, fontSize: 12)),
          ),
          pw.SizedBox(height: 18),
          for (final r in rounds) ...[
            pw.Text('الجولة $r',
                style: pw.TextStyle(font: bold, fontSize: 15)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: bold, fontSize: 11),
              cellStyle: pw.TextStyle(font: base, fontSize: 10),
              cellAlignment: pw.Alignment.center,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headers: const ['المباراة', 'التاريخ', 'الوقت', 'الحكم'],
              data: byRound[r]!
                  .map((m) => [
                        '${m.homeTeamName}  ×  ${m.awayTeamName}',
                        dateStr(m.dateTime),
                        timeStr(m.dateTime),
                        (m.refereeName != null && m.refereeName!.isNotEmpty)
                            ? m.refereeName!
                            : '—',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('📲 صُدِّر عبر تطبيق طوبة',
                style: pw.TextStyle(font: base, fontSize: 10,
                    color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'tournament_${tournament.id}.pdf',
    );
  }
}
