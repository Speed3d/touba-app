import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';

/// 📝 HINT AR: توليد تقرير PDF لجدول البطولة بدعم اللغات الثلاث (عربي، إنجليزي، كردي)
/// ترويسة بشعار «طوبة» واسم البطولة وحالتها، ثم كل المباريات بجولاتها وتواريخها وأوقاتها والحكّام والنتيجة.
class FixturesPdfService {
  static Future<void> shareTournamentSchedule({
    required TournamentModel tournament,
    required List<MatchModel> matches,
    String langCode = 'ar',
  }) async {
    final doc = pw.Document();
    final base = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    final isRtl = langCode != 'en';
    final textDir = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    // 📝 HINT AR: شعار طوبة الرسمي للترويسة (cache-first من الأصول).
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    // 📝 HINT AR: تجميع المباريات بالجولة + ترتيبها.
    final byRound = <int, List<MatchModel>>{};
    for (final m in matches) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();

    String dateStr(DateTime? dt) {
      if (dt == null) {
        return langCode == 'en' ? 'Unspecified' : (langCode == 'ku' ? 'دیارینەکراو' : 'غير محدد');
      }
      return DateFormat('yyyy/MM/dd', langCode == 'en' ? 'en' : 'ar').format(dt);
    }

    String timeStr(DateTime? dt) =>
        dt == null ? '—' : DateFormat('HH:mm').format(dt);

    String scoreStr(MatchModel m) =>
        m.resultConfirmed ? '${m.homeScore} - ${m.awayScore}' : '—';

    final String appName = langCode == 'en' ? 'Touba ⚽' : (langCode == 'ku' ? 'توبە ⚽' : 'طوبة ⚽');
    final String scheduleTitle = langCode == 'en'
        ? '${tournament.name} Tournament Schedule'
        : (langCode == 'ku'
            ? 'خشتەی پاڵەوانێتی ${tournament.name}'
            : 'جدول بطولة ${tournament.name}');

    final String statusLabel = tournament.status == 'finished'
        ? (langCode == 'en' ? 'Finished' : (langCode == 'ku' ? 'کۆتاییهاتوو' : 'منتهية'))
        : (tournament.status == 'ongoing'
            ? (langCode == 'en' ? 'Ongoing' : (langCode == 'ku' ? 'بەردەوامە' : 'جارية'))
            : (langCode == 'en' ? 'Upcoming' : (langCode == 'ku' ? 'داهاتوو' : 'قادمة')));

    final String cityLabel = langCode == 'en' ? 'City' : (langCode == 'ku' ? 'شار' : 'المدينة');
    final String statusPrefix = langCode == 'en' ? 'Status' : (langCode == 'ku' ? 'دۆخ' : 'الحالة');
    final String matchesLabel = langCode == 'en' ? 'Matches' : (langCode == 'ku' ? 'یارییەکان' : 'المباريات');

    final String headerMatch = langCode == 'en' ? 'Match' : (langCode == 'ku' ? 'یاری' : 'المباراة');
    final String headerResult = langCode == 'en' ? 'Result' : (langCode == 'ku' ? 'ئەنجام' : 'النتيجة');
    final String headerDate = langCode == 'en' ? 'Date' : (langCode == 'ku' ? 'بەروار' : 'التاريخ');
    final String headerTime = langCode == 'en' ? 'Time' : (langCode == 'ku' ? 'کات' : 'الوقت');
    final String headerReferee = langCode == 'en' ? 'Referee' : (langCode == 'ku' ? 'ناوبژیوان' : 'الحكم');

    String roundTitle(int r) {
      if (langCode == 'en') return 'Round $r';
      if (langCode == 'ku') return 'گەڕی $r';
      return 'الجولة $r';
    }

    final exportedAt = DateFormat('yyyy/MM/dd • HH:mm', langCode == 'en' ? 'en' : 'ar').format(DateTime.now());
    final exportFooter = langCode == 'en'
        ? '📲 Exported via Touba App — $exportedAt'
        : (langCode == 'ku'
            ? '📲 لە ڕێگەی ئەپی توبەوە دەرکراوە — $exportedAt'
            : '📲 صُدِّر عبر تطبيق طوبة — $exportedAt');

    doc.addPage(
      pw.MultiPage(
        textDirection: textDir,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // ── ترويسة العلامة ──
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
              pw.Text(appName,
                  style: pw.TextStyle(
                      font: bold, fontSize: 20, color: PdfColors.blue800)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(scheduleTitle,
                style: pw.TextStyle(font: bold, fontSize: 18)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
                '$cityLabel: ${tournament.city}  •  $statusPrefix: $statusLabel  •  $matchesLabel: ${matches.length}',
                style: pw.TextStyle(font: base, fontSize: 11)),
          ),
          pw.Divider(height: 18, color: PdfColors.grey400),
          for (final r in rounds) ...[
            pw.Text(roundTitle(r),
                style: pw.TextStyle(font: bold, fontSize: 15)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: bold, fontSize: 11),
              cellStyle: pw.TextStyle(font: base, fontSize: 10),
              cellAlignment: pw.Alignment.center,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headers: [
                headerMatch,
                headerResult,
                headerDate,
                headerTime,
                headerReferee,
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
            child: pw.Text(exportFooter,
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
