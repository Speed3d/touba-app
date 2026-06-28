import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';

/// 📝 HINT AR: توليد تقرير PDF لجدول البطولة (بند 12) — ترويسة بشعار «طوبة» واسم
/// البطولة وحالتها، ثم كل المباريات بجولاتها وتواريخها وأوقاتها والحكّام
/// و**النتيجة** (للمنتهية). يستخدم خطّ Cairo مع اتجاه RTL ليظهر العربي صحيحاً.
class FixturesPdfService {
  static Future<void> shareTournamentSchedule({
    required TournamentModel tournament,
    required List<MatchModel> matches,
  }) async {
    final doc = pw.Document();
    final base = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    // 📝 HINT AR: شعار طوبة الرسمي للترويسة (cache-first من الأصول).
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null; // إن تعذّر تحميل الشعار نكمل بلا صورة.
    }

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
    // 📝 HINT AR: عمود النتيجة — السكور للمباريات المنتهية فقط، وإلا «—».
    String scoreStr(MatchModel m) =>
        m.resultConfirmed ? '${m.homeScore} - ${m.awayScore}' : '—';

    final statusLabel = tournament.status == 'finished'
        ? 'منتهية'
        : (tournament.status == 'ongoing' ? 'جارية' : 'قادمة');
    final exportedAt =
        DateFormat('yyyy/MM/dd • HH:mm', 'ar').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // ── ترويسة العلامة (شعار طوبة + اسم البطولة) ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 44,
                  height: 44,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 10),
              ],
              pw.Text('طوبة ⚽',
                  style: pw.TextStyle(
                      font: bold, fontSize: 20, color: PdfColors.blue800)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('جدول بطولة ${tournament.name}',
                style: pw.TextStyle(font: bold, fontSize: 18)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
                'المدينة: ${tournament.city}  •  الحالة: $statusLabel  •  المباريات: ${matches.length}',
                style: pw.TextStyle(font: base, fontSize: 11)),
          ),
          pw.Divider(height: 18, color: PdfColors.grey400),
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
              headers: const [
                'المباراة',
                'النتيجة',
                'التاريخ',
                'الوقت',
                'الحكم'
              ],
              data: byRound[r]!
                  .map((m) => [
                        '${m.homeTeamName}  ×  ${m.awayTeamName}',
                        scoreStr(m),
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
            child: pw.Text('📲 صُدِّر عبر تطبيق طوبة — $exportedAt',
                style: pw.TextStyle(
                    font: base, fontSize: 10, color: PdfColors.grey600)),
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
