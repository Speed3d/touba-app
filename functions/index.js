const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * دالة سحابية تعمل عند تأكيد نتيجة المباراة
 * تقوم بتحديث:
 * 1. إحصائيات الفرق (لعب، فاز، خسر، تعادل، أهداف، نقاط التصنيف)
 * 2. جدول ترتيب البطولة (النقاط، فارق الأهداف)
 */
exports.onMatchResultConfirmed = functions.firestore
  .document("matches/{matchId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // تأكد من أن النتيجة تم تأكيدها للتو
    if (beforeData.resultConfirmed === true || afterData.resultConfirmed !== true) {
      return null;
    }

    const { homeTeamId, awayTeamId, homeScore, awayScore, tournamentId } = afterData;

    // تشغيل العملية داخل Transaction لضمان الأمان وعدم تضارب البيانات
    return db.runTransaction(async (transaction) => {
      const homeTeamRef = db.collection("teams").doc(homeTeamId);
      const awayTeamRef = db.collection("teams").doc(awayTeamId);
      const tournamentRef = db.collection("tournaments").doc(tournamentId);

      const [homeTeamDoc, awayTeamDoc, tournamentDoc] = await Promise.all([
        transaction.get(homeTeamRef),
        transaction.get(awayTeamRef),
        transaction.get(tournamentRef),
      ]);

      if (!homeTeamDoc.exists || !awayTeamDoc.exists) {
        throw new Error("أحد الفرق أو كلاهما غير موجود في قاعدة البيانات.");
      }

      // ============================================
      // 1. حساب وتحديث إحصائيات الفرق (Teams Stats)
      // ============================================
      const homeStats = homeTeamDoc.data().stats || { played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0 };
      const awayStats = awayTeamDoc.data().stats || { played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0 };
      
      let homePointsDiff = 0;
      let awayPointsDiff = 0;

      // تحديث عدد المباريات الملعوبة والأهداف
      homeStats.played += 1;
      homeStats.goalsFor += homeScore;
      homeStats.goalsAgainst += awayScore;

      awayStats.played += 1;
      awayStats.goalsFor += awayScore;
      awayStats.goalsAgainst += homeScore;

      // تحديد الفائز والخاسر وإعطاء نقاط التصنيف (Rating/Elo)
      if (homeScore > awayScore) {
        homeStats.wins += 1;
        awayStats.losses += 1;
        homePointsDiff = 30;  // نقاط مكسب
        awayPointsDiff = -15; // خصم نقاط
      } else if (homeScore < awayScore) {
        homeStats.losses += 1;
        awayStats.wins += 1;
        homePointsDiff = -15;
        awayPointsDiff = 30;
      } else {
        homeStats.draws += 1;
        awayStats.draws += 1;
        homePointsDiff = 5;
        awayPointsDiff = 5;
      }

      const newHomeRating = (homeTeamDoc.data().ratingPoints || 1200) + homePointsDiff;
      const newAwayRating = (awayTeamDoc.data().ratingPoints || 1200) + awayPointsDiff;

      transaction.update(homeTeamRef, {
        stats: homeStats,
        ratingPoints: newHomeRating
      });

      transaction.update(awayTeamRef, {
        stats: awayStats,
        ratingPoints: newAwayRating
      });

      // ============================================
      // 2. تحديث جدول ترتيب البطولة (Tournament Standings)
      // ============================================
      if (tournamentDoc.exists && tournamentDoc.data().type === 'league') {
        const standings = tournamentDoc.data().standings || [];
        
        // دالة مساعدة لتحديث أو إضافة فريق إلى الترتيب
        const updateStandingsForTeam = (teamId, goalsFor, goalsAgainst, isWin, isDraw, isLoss) => {
          let teamEntry = standings.find(s => s.teamId === teamId);
          if (!teamEntry) {
            teamEntry = { teamId, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, gd: 0, points: 0 };
            standings.push(teamEntry);
          }
          teamEntry.played += 1;
          teamEntry.gf += goalsFor;
          teamEntry.ga += goalsAgainst;
          teamEntry.gd = teamEntry.gf - teamEntry.ga; // فارق الأهداف
          if (isWin) {
            teamEntry.won += 1;
            teamEntry.points += 3;
          } else if (isDraw) {
            teamEntry.drawn += 1;
            teamEntry.points += 1;
          } else if (isLoss) {
            teamEntry.lost += 1;
          }
        };

        const homeWin = homeScore > awayScore;
        const awayWin = awayScore > homeScore;
        const draw = homeScore === awayScore;

        updateStandingsForTeam(homeTeamId, homeScore, awayScore, homeWin, draw, awayWin);
        updateStandingsForTeam(awayTeamId, awayScore, homeScore, awayWin, draw, homeWin);

        // ترتيب الجدول: بناءً على النقاط، ثم فارق الأهداف، ثم الأهداف المسجلة
        standings.sort((a, b) => {
          if (b.points !== a.points) return b.points - a.points;
          if (b.gd !== a.gd) return b.gd - a.gd;
          return b.gf - a.gf;
        });

        transaction.update(tournamentRef, { standings });
      }
    });
  });
