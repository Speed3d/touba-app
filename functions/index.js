// ============================================================================
// ☁️ Cloud Functions — منصة «طوبة» ⚽ (مشروع touba-3ds)
// ============================================================================
// 📝 HINT AR: كُتبت بصياغة الجيل الثاني (v2) المتوافقة مع firebase-functions ^7.
// المحرّك الأهم onMatchResultConfirmed: تحديث ذرّي (معاملة واحدة) لإحصائيات
// الفرق واللاعبين والتصنيف وترتيب البطولة، مع:
//   • Idempotency  : لا يُحتسب مرّتين (عبر العلم statsApplied).
//   • Reverse-Apply: عند تعديل نتيجة مؤكّدة، يتراجع عن القديم ثم يطبّق الجديد
//                    (عبر البصمة appliedSnapshot) — يمنع تضاعف الإحصائيات.
// راجع «تصميم_الأساس.md» القسم 9.
// ============================================================================

const {onDocumentUpdated, onDocumentWritten, onDocumentCreated} =
  require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// 📝 HINT AR: منطقة قريبة لتقليل زمن الاستجابة (توصية الخطة).
setGlobalOptions({region: "europe-west1", maxInstances: 10});

// 📝 HINT AR: نقاط التصنيف العام (شبيه FIFA، أساس 1200) — تطابق الخطة.
const RATING = {WIN: 20, DRAW: 5, LOSS: -10};
// 📝 HINT AR: نقاط الفريق العامة (مجمّعة عبر كل المباريات) — النظام القياسي.
const TEAM_POINTS = {WIN: 3, DRAW: 1, LOSS: 0};

// ─── دوال مساعدة خالصة ──────────────────────────────────────────────────

function zeroStats() {
  return {played: 0, wins: 0, draws: 0, losses: 0,
    goalsFor: 0, goalsAgainst: 0, points: 0};
}
function zeroCareer() {
  return {matches: 0, goals: 0, assists: 0, yellowCards: 0, redCards: 0,
    rating: 0};
}
// 📝 HINT AR: توكن عشوائي (لعضوية الفريق teamToken) — أحرف/أرقام واضحة.
function genToken(len = 8) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let s = "";
  for (let i = 0; i < len; i++) {
    s += chars[Math.floor(Math.random() * chars.length)];
  }
  return s;
}
// 📝 HINT AR: بصمة النتيجة المؤثّرة على الإحصائيات (للمقارنة والتراجع).
function snapshotOf(data) {
  return {
    homeScore: data.homeScore || 0,
    awayScore: data.awayScore || 0,
    events: data.events || [],
    lineup: data.lineup || [],
  };
}
function outcome(gf, ga) {
  if (gf > ga) return "win";
  if (gf < ga) return "loss";
  return "draw";
}
function invert(o) {
  if (o === "win") return "loss";
  if (o === "loss") return "win";
  return "draw";
}
// 📝 HINT AR: تطبيق نتيجة على إحصائيات فريق (sign=+1 تطبيق، -1 تراجع).
function applyOutcomeToStats(stats, o, sign) {
  if (o === "win") {
    stats.wins += sign; stats.points += sign * TEAM_POINTS.WIN;
  } else if (o === "loss") {
    stats.losses += sign; stats.points += sign * TEAM_POINTS.LOSS;
  } else {
    stats.draws += sign; stats.points += sign * TEAM_POINTS.DRAW;
  }
}
// 📝 HINT AR: تحديث صفّ فريق في جدول ترتيب البطولة (مع التراجع عبر sign).
// group = اسم المجموعة (للمجموعات) ليُفرز كل صفّ ضمن مجموعته.
function updateStanding(standings, teamId, gf, ga, o, sign, rule, group) {
  let e = standings.find((s) => s.teamId === teamId);
  if (!e) {
    e = {teamId, played: 0, won: 0, drawn: 0, lost: 0,
      gf: 0, ga: 0, gd: 0, points: 0};
    if (group) e.group = group;
    standings.push(e);
  } else if (group && !e.group) {
    e.group = group;
  }
  e.played += sign;
  e.gf += sign * gf;
  e.ga += sign * ga;
  e.gd = e.gf - e.ga;
  if (o === "win") {
    e.won += sign; e.points += sign * (rule.win != null ? rule.win : 3);
  } else if (o === "loss") {
    e.lost += sign; e.points += sign * (rule.loss != null ? rule.loss : 0);
  } else {
    e.drawn += sign; e.points += sign * (rule.draw != null ? rule.draw : 1);
  }
}
// 📝 HINT AR: فرز الترتيب: المجموعة ← النقاط ← فارق الأهداف ← الأهداف المسجّلة.
function sortStandings(s) {
  s.sort((a, b) =>
    String(a.group || "").localeCompare(String(b.group || "")) ||
    (b.points - a.points) || (b.gd - a.gd) || (b.gf - a.gf));
}

// ============================================================================
// 1) المحرّك الذرّي — عند تأكيد/تعديل نتيجة مباراة
// ============================================================================
exports.onMatchResultConfirmed = onDocumentUpdated(
  "matches/{matchId}",
  async (event) => {
    const after = event.data.after.data();
    if (!after) return;

    // البصمة المطلوب تطبيقها (إن كانت النتيجة مؤكّدة) والبصمة المطبّقة سابقاً.
    const desired = after.resultConfirmed === true ? snapshotOf(after) : null;
    const applied = after.statsApplied === true ?
      (after.appliedSnapshot || null) : null;

    // 📝 HINT AR: حارس منع الحلقة اللانهائية — لا تغيير فعلي على الإحصائيات.
    if (JSON.stringify(desired) === JSON.stringify(applied)) return;

    const matchRef = event.data.after.ref;
    const {homeTeamId, awayTeamId, tournamentId} = after;
    if (!homeTeamId || !awayTeamId) return;
    // 📝 HINT AR: مرحلة المباراة — الترتيب يُحدَّث لمباريات الدوري/المجموعات فقط
    // (الإقصائي بلا جدول ترتيب). groupName لإسناد صفّ كل فريق لمجموعته.
    const stage = after.stage || "league";
    const groupName = after.groupName || null;

    // اجمع معرّفات اللاعبين من البصمتين (لقراءتهم مرّة واحدة).
    const playerIds = new Set();
    for (const snap of [applied, desired]) {
      if (!snap) continue;
      for (const ev of (snap.events || [])) {
        if (ev.playerId && ev.type !== "owngoal") playerIds.add(ev.playerId);
      }
      for (const pid of (snap.lineup || [])) {
        if (pid) playerIds.add(pid);
      }
    }

    await db.runTransaction(async (tx) => {
      const homeRef = db.collection("teams").doc(homeTeamId);
      const awayRef = db.collection("teams").doc(awayTeamId);
      const tournRef = tournamentId ?
        db.collection("tournaments").doc(tournamentId) : null;
      const playerRefs = {};
      for (const pid of playerIds) {
        playerRefs[pid] = db.collection("players").doc(pid);
      }

      // ── كل القراءات أولاً (شرط معاملات Firestore) ──
      const [homeDoc, awayDoc, tournDoc] = await Promise.all([
        tx.get(homeRef),
        tx.get(awayRef),
        tournRef ? tx.get(tournRef) : Promise.resolve(null),
      ]);
      const playerDocs = {};
      await Promise.all([...playerIds].map(async (pid) => {
        playerDocs[pid] = await tx.get(playerRefs[pid]);
      }));

      if (!homeDoc.exists || !awayDoc.exists) {
        logger.warn("فريق مفقود — تخطّي المعالجة", {homeTeamId, awayTeamId});
        return;
      }

      // ── الحساب في الذاكرة ──
      const homeStats = homeDoc.data().stats || zeroStats();
      const awayStats = awayDoc.data().stats || zeroStats();
      let homeRating = homeDoc.data().ratingPoints || 1200;
      let awayRating = awayDoc.data().ratingPoints || 1200;
      const playerStats = {};
      for (const pid of playerIds) {
        playerStats[pid] = playerDocs[pid].exists ?
          (playerDocs[pid].data().careerStats || zeroCareer()) : zeroCareer();
      }
      // 📝 HINT AR: جدول الترتيب لمباريات الدوري/المجموعات فقط (الإقصائي بلا ترتيب
      // حتى داخل بطولة المجموعات). يُسند الصفّ لمجموعته عبر groupName.
      const isStandingsMatch = stage === "league" || stage === "group";
      const standings = (isStandingsMatch && tournDoc && tournDoc.exists) ?
        (tournDoc.data().standings || []) : null;
      const rule = (tournDoc && tournDoc.exists &&
          tournDoc.data().pointsRule) || {win: 3, draw: 1, loss: 0};

      const applyDelta = (snap, sign) => {
        if (!snap) return;
        const hs = snap.homeScore;
        const as = snap.awayScore;
        homeStats.played += sign; awayStats.played += sign;
        homeStats.goalsFor += sign * hs; homeStats.goalsAgainst += sign * as;
        awayStats.goalsFor += sign * as; awayStats.goalsAgainst += sign * hs;
        const ho = outcome(hs, as);
        const ao = invert(ho);
        applyOutcomeToStats(homeStats, ho, sign);
        applyOutcomeToStats(awayStats, ao, sign);
        homeRating += sign * RATING[ho.toUpperCase()];
        awayRating += sign * RATING[ao.toUpperCase()];
        if (standings) {
          updateStanding(
            standings, homeTeamId, hs, as, ho, sign, rule, groupName);
          updateStanding(
            standings, awayTeamId, as, hs, ao, sign, rule, groupName);
        }
        // إحصائيات اللاعبين من أحداث المباراة (الهدف بالخطأ لا يُحتسب للاعب).
        for (const ev of (snap.events || [])) {
          if (!ev.playerId || ev.type === "owngoal") continue;
          const cs = playerStats[ev.playerId];
          if (!cs) continue;
          if (ev.type === "goal") cs.goals += sign;
          else if (ev.type === "assist") cs.assists += sign;
          else if (ev.type === "yellow") cs.yellowCards += sign;
          else if (ev.type === "red") cs.redCards += sign;
        }
        // عدد المباريات: لكل لاعب ضمن تشكيلة المباراة.
        for (const pid of (snap.lineup || [])) {
          const cs = playerStats[pid];
          if (cs) cs.matches += sign;
        }
      };

      applyDelta(applied, -1); // تراجع عن القديم
      applyDelta(desired, +1); // تطبيق الجديد
      if (standings) sortStandings(standings);

      // ── كل الكتابات ──
      tx.update(homeRef, {stats: homeStats, ratingPoints: homeRating});
      tx.update(awayRef, {stats: awayStats, ratingPoints: awayRating});
      if (tournRef && standings) tx.update(tournRef, {standings});
      for (const pid of playerIds) {
        if (playerDocs[pid].exists) {
          tx.update(playerRefs[pid], {careerStats: playerStats[pid]});
        }
      }
      // 📝 HINT AR: تثبيت البصمة (Idempotency) — عند إلغاء التأكيد نحذف البصمة.
      tx.update(matchRef, {
        statsApplied: !!desired,
        appliedSnapshot: desired ||
            admin.firestore.FieldValue.delete(),
      });
    });

    // 📝 HINT AR: ملاحظة — عدد المباريات للاعب (matches) يحتاج تشكيلة لكل
    // مباراة (lineup) وهي خارج نطاق MVP؛ يُضاف في المرحلة 2.

    // ── ترقية الإقصائي + تقدّم البطولة (الوجبة 7) ─────────────────────
    if (desired && tournamentId) {
      // 📝 HINT AR: مباراة إقصائية مؤكّدة → يصعد فائزها لخانة المباراة التالية
      // (homeFeedFrom/awayFeedFrom). يُعاد الحساب عند تعديل النتيجة (تصحيح).
      if (stage === "knockout") {
        try {
          await advanceKnockoutWinner(matchRef.id, after);
        } catch (e) {
          logger.warn("تعذّر ترقية الفائز", {error: `${e}`});
        }
      }
      // 📝 HINT AR: مجموعات اكتملت → توليد الإقصائي؛ وإلا كشف البطل عند الاكتمال.
      try {
        await maybeAdvanceTournament(tournamentId);
      } catch (e) {
        logger.warn("تعذّر تقدّم البطولة", {tournamentId, error: `${e}`});
      }
    }
  },
);

// 📝 HINT AR: يصعّد فائز مباراة إقصائية إلى خانته في المباراة التالية. الفائز =
// advancedTeamId (للتعادل المحسوم بالجزاءات/الإضافي) وإلا الأعلى نتيجةً. نبحث عن
// المباريات التي تُغذّى من هذه (feed) ونملأ خانتها. معرّف المباراة فريد عالمياً
// فلا حاجة لفلترة tournamentId (فهرس مفرد تلقائي على homeFeedFrom/awayFeedFrom).
async function advanceKnockoutWinner(matchId, m) {
  let winnerId = m.advancedTeamId || null;
  if (!winnerId) {
    const hs = m.homeScore || 0;
    const as = m.awayScore || 0;
    if (hs > as) winnerId = m.homeTeamId;
    else if (as > hs) winnerId = m.awayTeamId;
    else return; // تعادل بلا متأهّل محدّد — ننتظر تحديد المنظّم
  }
  const isHome = winnerId === m.homeTeamId;
  const winnerName = isHome ? m.homeTeamName : m.awayTeamName;
  const winnerLogo = (isHome ? m.homeTeamLogo : m.awayTeamLogo) || null;

  const [homeChildren, awayChildren] = await Promise.all([
    db.collection("matches").where("homeFeedFrom", "==", matchId).get(),
    db.collection("matches").where("awayFeedFrom", "==", matchId).get(),
  ]);
  const batch = db.batch();
  homeChildren.forEach((d) => batch.update(d.ref, {
    homeTeamId: winnerId, homeTeamName: winnerName, homeTeamLogo: winnerLogo,
  }));
  awayChildren.forEach((d) => batch.update(d.ref, {
    awayTeamId: winnerId, awayTeamName: winnerName, awayTeamLogo: winnerLogo,
  }));
  if (!homeChildren.empty || !awayChildren.empty) await batch.commit();
}

// 📝 HINT AR: بعد كل نتيجة — إن كانت بطولة مجموعات لم يُولَّد إقصائيها بعد، نحاول
// توليده (يتحقق داخلياً من اكتمال المجموعات)؛ وإلا نحاول إنهاء البطولة وكشف البطل.
async function maybeAdvanceTournament(tournamentId) {
  const tDoc = await db.collection("tournaments").doc(tournamentId).get();
  if (!tDoc.exists) return;
  const t = tDoc.data();
  if (t.type === "groups" && !t.bracketGenerated) {
    await generateKnockoutFromGroupsInternal(tournamentId);
    return;
  }
  await finalizeTournamentIfDone(tournamentId);
}

// 📝 HINT AR: يُنهي البطولة ويحدّد الفائز إن اكتملت كل مبارياتها.
async function finalizeTournamentIfDone(tournamentId) {
  const matchesSnap = await db.collection("matches")
    .where("tournamentId", "==", tournamentId).get();
  if (matchesSnap.empty) return;
  const allConfirmed = matchesSnap.docs
    .every((d) => d.data().resultConfirmed === true);
  if (!allConfirmed) return;

  const tournRef = db.collection("tournaments").doc(tournamentId);
  const tournDoc = await tournRef.get();
  if (!tournDoc.exists) return;
  const t = tournDoc.data();
  if (t.status === "finished") return; // مُنهاة سابقاً

  // الفائز: متصدّر الترتيب (للدوري) وإلا فائز النهائي الإقصائي (للإقصائي/المجموعات).
  let winnerTeamId = null;
  if (t.type === "league") {
    const standings = t.standings || [];
    if (standings.length > 0) winnerTeamId = standings[0].teamId || null;
  } else {
    // إقصائي/مجموعات: فائز النهائي (أعلى bracketRound ضمن مباريات الإقصائي).
    let finalMatch = null;
    matchesSnap.docs.forEach((d) => {
      const m = d.data();
      if ((m.stage || "") !== "knockout") return;
      if (!finalMatch ||
          (m.bracketRound || 0) > (finalMatch.bracketRound || 0)) {
        finalMatch = m;
      }
    });
    if (finalMatch) {
      winnerTeamId = finalMatch.advancedTeamId ||
        ((finalMatch.homeScore >= finalMatch.awayScore) ?
          finalMatch.homeTeamId : finalMatch.awayTeamId);
    }
  }

  // اسم الفائز (denormalized) — من أسماء الفرق المخزّنة على المباريات.
  let winnerTeamName = null;
  if (winnerTeamId) {
    for (const d of matchesSnap.docs) {
      const m = d.data();
      if (m.homeTeamId === winnerTeamId) {
        winnerTeamName = m.homeTeamName; break;
      }
      if (m.awayTeamId === winnerTeamId) {
        winnerTeamName = m.awayTeamName; break;
      }
    }
  }

  await tournRef.update({
    status: "finished",
    winnerTeamId: winnerTeamId,
    winnerTeamName: winnerTeamName,
    endDate: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ============================================================================
// ترقية المجموعات → إقصائي (الوجبة 7) — بناء الشجرة من المتأهّلين
// ============================================================================
// 📝 HINT AR: ترتيب البذور القياسي (مطابق fixtures_service.dart).
function seedOrderJs(size) {
  let order = [1];
  while (order.length < size) {
    const n = order.length * 2;
    const next = [];
    for (const s of order) {
      next.push(s);
      next.push(n + 1 - s);
    }
    order = next;
  }
  return order;
}

// 📝 HINT AR: يبني شجرة إقصائية من بذور مرتّبة (الأقوى أولاً) + دعم Bye.
function buildBracketJs(seeds) {
  const n = seeds.length;
  if (n < 2) return [];
  let p = 1;
  while (p < n) p *= 2;
  const order = seedOrderJs(p);
  const teamOf = (seed) => (seed <= n ? seeds[seed - 1] : "__BYE__");
  const fixtures = [];
  let counter = 0;
  let round = 1;
  let advancers = [];
  for (let i = 0; i < p; i += 2) {
    const a = teamOf(order[i]);
    const b = teamOf(order[i + 1]);
    const aBye = a === "__BYE__";
    const bBye = b === "__BYE__";
    if (aBye && bBye) continue;
    else if (aBye) advancers.push({team: b});
    else if (bBye) advancers.push({team: a});
    else {
      const key = `K${round}_${counter++}`;
      fixtures.push({round, homeId: a, awayId: b, bracketRound: round, key});
      advancers.push({feed: key});
    }
  }
  while (advancers.length > 1) {
    round++;
    counter = 0;
    const next = [];
    for (let i = 0; i < advancers.length; i += 2) {
      const s1 = advancers[i];
      const s2 = advancers[i + 1];
      const key = `K${round}_${counter++}`;
      fixtures.push({
        round, homeId: s1.team || "", awayId: s2.team || "",
        bracketRound: round, key,
        homeFeedKey: s1.feed || null, awayFeedKey: s2.feed || null,
      });
      next.push({feed: key});
    }
    advancers = next;
  }
  return fixtures;
}

// 📝 HINT AR: يولّد المرحلة الإقصائية من المجموعات بعد اكتمالها (idempotent عبر
// bracketGenerated). البذور = متأهّلو كل مجموعة بترتيب القوّة (المتصدّرون ثم
// الوصفاء...) فيُنتج التزاوج القياسي A1×B2، B1×A2.
async function generateKnockoutFromGroupsInternal(tournamentId) {
  const tRef = db.collection("tournaments").doc(tournamentId);
  const tDoc = await tRef.get();
  if (!tDoc.exists) return;
  const t = tDoc.data();
  if (t.type !== "groups" || t.bracketGenerated === true) return;

  const groups = t.groups || {};
  const groupNames = Object.keys(groups).sort();
  if (groupNames.length === 0) return;

  const groupMatches = await db.collection("matches")
    .where("tournamentId", "==", tournamentId)
    .where("stage", "==", "group").get();
  if (groupMatches.empty) return;
  if (!groupMatches.docs.every((d) => d.data().resultConfirmed === true)) {
    return; // المجموعات لم تكتمل بعد
  }

  const standings = t.standings || [];
  const q = t.qualifiersPerGroup || 2;
  const byGroup = {};
  for (const g of groupNames) byGroup[g] = [];
  for (const row of standings) {
    if (row.group && byGroup[row.group]) byGroup[row.group].push(row);
  }
  for (const g of groupNames) {
    byGroup[g].sort((a, b) =>
      (b.points - a.points) || (b.gd - a.gd) || (b.gf - a.gf));
  }
  // البذور: كل المتصدّرين (بترتيب المجموعات) ثم الوصفاء ثم الثوالث...
  const seeds = [];
  for (let rank = 0; rank < q; rank++) {
    for (const g of groupNames) {
      if (byGroup[g][rank]) seeds.push(byGroup[g][rank].teamId);
    }
  }
  if (seeds.length < 2) return;

  const bracket = buildBracketJs(seeds);

  const teamDocs = {};
  await Promise.all(seeds.map(async (id) => {
    teamDocs[id] = await db.collection("teams").doc(id).get();
  }));
  const nameOf = (id) =>
    (id && teamDocs[id] && teamDocs[id].exists) ?
      (teamDocs[id].data().name || "") : "";
  const logoOf = (id) =>
    (id && teamDocs[id] && teamDocs[id].exists) ?
      (teamDocs[id].data().logoUrl || null) : null;

  const idByKey = {};
  for (const f of bracket) {
    if (f.key) idByKey[f.key] = db.collection("matches").doc().id;
  }
  const fv = admin.firestore.FieldValue;
  const batch = db.batch();
  for (const f of bracket) {
    const mid = f.key ? idByKey[f.key] : db.collection("matches").doc().id;
    batch.set(db.collection("matches").doc(mid), {
      tournamentId,
      round: f.round,
      stage: "knockout",
      bracketRound: f.bracketRound,
      homeTeamId: f.homeId || "",
      awayTeamId: f.awayId || "",
      homeTeamName: nameOf(f.homeId),
      awayTeamName: nameOf(f.awayId),
      homeTeamLogo: logoOf(f.homeId),
      awayTeamLogo: logoOf(f.awayId),
      homeFeedFrom: f.homeFeedKey ? idByKey[f.homeFeedKey] : null,
      awayFeedFrom: f.awayFeedKey ? idByKey[f.awayFeedKey] : null,
      status: "upcoming",
      homeScore: 0,
      awayScore: 0,
      events: [],
      lineup: [],
      resultConfirmed: false,
      decidedBy: "none",
      createdAt: fv.serverTimestamp(),
      updatedAt: fv.serverTimestamp(),
    });
  }
  batch.update(tRef, {bracketGenerated: true, updatedAt: fv.serverTimestamp()});
  await batch.commit();
}

// 📝 HINT AR: توليد يدوي للمرحلة الإقصائية (زر احتياطي للمنظّم/الأدمن).
exports.generateKnockout = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل الدخول أولاً");
  const tournamentId = (request.data || {}).tournamentId;
  if (!tournamentId) {
    throw new HttpsError("invalid-argument", "معرّف البطولة مطلوب");
  }
  const tDoc = await db.collection("tournaments").doc(tournamentId).get();
  if (!tDoc.exists) throw new HttpsError("not-found", "البطولة غير موجودة");
  const isAdmin = request.auth.token && request.auth.token.admin === true;
  if (!isAdmin && tDoc.data().organizerUid !== uid) {
    throw new HttpsError("permission-denied", "للمنظّم أو الأدمن فقط");
  }
  await generateKnockoutFromGroupsInternal(tournamentId);
  return {success: true};
});

// ============================================================================
// 2) منح/سحب صلاحية لمستخدم (للأدمن فقط) — C6
// ============================================================================
exports.grantCapability = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "هذه العملية للأدمن فقط.");
  }
  const {uid, capability, value} = request.data || {};
  const allowed = ["organizer", "referee", "admin"];
  if (!uid || !allowed.includes(capability)) {
    throw new HttpsError("invalid-argument", "بيانات غير صالحة.");
  }
  const user = await admin.auth().getUser(uid);
  const claims = Object.assign({}, user.customClaims || {});
  if (value) claims[capability] = true;
  else delete claims[capability];
  await admin.auth().setCustomUserClaims(uid, claims);

  // مرآة في Firestore للعرض والإدارة من اللوحة.
  const fv = admin.firestore.FieldValue;
  await db.collection("users").doc(uid).set({
    adminPermissions: value ?
      fv.arrayUnion(capability) : fv.arrayRemove(capability),
    updatedAt: fv.serverTimestamp(),
  }, {merge: true});

  return {success: true};
});

// ============================================================================
// 3) المطالبة بسجل لاعب عبر رابط الدعوة — C4
// ============================================================================
exports.claimPlayerViaInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }
  const uid = request.auth.uid;
  const token = (request.data || {}).token;
  if (!token) throw new HttpsError("invalid-argument", "رمز الدعوة مطلوب.");

  // 📝 HINT AR: الاستعلام يتم خارج المعاملة (المعاملات لا تدعم الاستعلامات).
  const q = await db.collection("claim_invites")
    .where("token", "==", token)
    .where("status", "==", "pending")
    .limit(1).get();
  if (q.empty) {
    throw new HttpsError("not-found", "رابط الدعوة غير صالح أو مُستخدَم.");
  }
  const inviteRef = q.docs[0].ref;
  const invite = q.docs[0].data();
  if (invite.expiresAt && invite.expiresAt.toMillis() < Date.now()) {
    throw new HttpsError("deadline-exceeded", "انتهت صلاحية رابط الدعوة.");
  }

  const playerRef = db.collection("players").doc(invite.playerId);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const [playerDoc, inviteDoc] = await Promise.all([
      tx.get(playerRef), tx.get(inviteRef),
    ]);
    if (!inviteDoc.exists || inviteDoc.data().status !== "pending") {
      throw new HttpsError("failed-precondition", "تم استخدام الدعوة مسبقاً.");
    }
    if (!playerDoc.exists) {
      throw new HttpsError("not-found", "سجل اللاعب غير موجود.");
    }
    if (playerDoc.data().claimedByUid) {
      throw new HttpsError("already-exists", "هذا اللاعب مرتبط بحساب آخر.");
    }
    const fv = admin.firestore.FieldValue;
    tx.update(playerRef, {claimedByUid: uid, updatedAt: fv.serverTimestamp()});
    tx.set(userRef, {
      linkedPlayerId: invite.playerId, updatedAt: fv.serverTimestamp(),
    }, {merge: true});
    tx.update(inviteRef, {status: "used", usedBy: uid});
  });

  return {success: true, playerId: invite.playerId};
});

// ============================================================================
// 3.1) ربط لاعب بكوده الدائم — الكابتن يُدخل كود اللاعب (هوية دائمة)
// ============================================================================
// 📝 HINT AR: الكابتن يُدخل كود اللاعب الدائم (playerCode). نُنشئ/ننقل سجل لاعب
// دائم مرتبط بحسابه إلى فريق الكابتن، ونجدّد teamToken (توكن العضوية). الإحصائيات
// تبقى عبر الانتقالات. يُرفض إن كان اللاعب مرتبطاً بفريق آخر (يجب خروجه أولاً).
exports.linkPlayerByCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }
  const captainUid = request.auth.uid;
  const {teamId, playerCode} = request.data || {};
  if (!teamId || !playerCode) {
    throw new HttpsError("invalid-argument", "بيانات غير صالحة.");
  }
  const teamSnap = await db.collection("teams").doc(teamId).get();
  if (!teamSnap.exists) {
    throw new HttpsError("not-found", "الفريق غير موجود.");
  }
  if (teamSnap.data().captainId !== captainUid) {
    throw new HttpsError("permission-denied", "هذه العملية لكابتن الفريق فقط.");
  }

  const code = String(playerCode).trim().toUpperCase();
  const uq = await db.collection("users")
    .where("playerCode", "==", code).limit(1).get();
  if (uq.empty) {
    throw new HttpsError("not-found", "لا يوجد لاعب بهذا الكود.");
  }
  const userId = uq.docs[0].id;
  const userData = uq.docs[0].data();
  const fv = admin.firestore.FieldValue;
  const teamToken = genToken();

  let playerId = userData.linkedPlayerId || null;
  let playerData = null;
  if (playerId) {
    const pSnap = await db.collection("players").doc(playerId).get();
    if (pSnap.exists) {
      playerData = pSnap.data();
    } else {
      playerId = null;
    }
  }
  if (playerData && playerData.currentTeamId &&
      playerData.currentTeamId !== "" &&
      playerData.currentTeamId !== teamId) {
    throw new HttpsError("failed-precondition",
      "اللاعب مرتبط بفريق آخر — يجب خروجه من فريقه أولاً.");
  }

  if (playerId) {
    await db.collection("players").doc(playerId).update({
      currentTeamId: teamId,
      teamToken: teamToken,
      updatedAt: fv.serverTimestamp(),
    });
  } else {
    const ref = db.collection("players").doc();
    await ref.set({
      name: userData.name || "لاعب",
      photoUrl: userData.profileImage || null,
      position: "غير محدد",
      shirtNumber: null,
      preferredFoot: null,
      height: null,
      weight: null,
      status: "active",
      isStarter: true,
      currentTeamId: teamId,
      careerStats: zeroCareer(),
      claimedByUid: userId,
      createdByUid: captainUid,
      teamToken: teamToken,
      createdAt: fv.serverTimestamp(),
      updatedAt: fv.serverTimestamp(),
    });
    playerId = ref.id;
    await db.collection("users").doc(userId).set(
      {linkedPlayerId: playerId, updatedAt: fv.serverTimestamp()},
      {merge: true});
  }

  await _sendUserNotification(
    userId,
    "تمت إضافتك إلى فريق ⚽",
    `أضافك كابتن ${teamSnap.data().name || "الفريق"} إلى تشكيلته.`,
    "addedToTeam",
    {teamId},
  );
  return {success: true, playerId};
});

// ============================================================================
// 4) عند قبول طلب انضمام: ربط/إنشاء سجل لاعب دائم لصاحب الطلب
// ============================================================================
exports.onJoinRequestAccepted = onDocumentUpdated(
  "join_requests/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "accepted") return;

    const {teamId, userId, userName} = after;
    const reqRef = event.data.after.ref;
    const teamRef = db.collection("teams").doc(teamId);
    const userRef = db.collection("users").doc(userId);
    const fv = admin.firestore.FieldValue;

    // 📝 HINT AR: حارس التعارض — إن كان اللاعب مسجّلاً بفريق آخر بالفعل، لا ننقله
    // (أول من يقبل يفوز). نُرجع الطلب لحالة player_in_other_team ونُشعر الكابتن.
    const userSnap = await userRef.get();
    const existingPid =
      userSnap.exists ? (userSnap.data().linkedPlayerId || null) : null;
    if (existingPid) {
      const pSnap = await db.collection("players").doc(existingPid).get();
      if (pSnap.exists) {
        const curTeam = pSnap.data().currentTeamId || "";
        if (curTeam && curTeam !== teamId) {
          const otherSnap = await db.collection("teams").doc(curTeam).get();
          const otherName = otherSnap.exists ?
            (otherSnap.data().name || "فريق آخر") : "فريق آخر";
          await reqRef.update({status: "player_in_other_team"});
          const teamSnap0 = await teamRef.get();
          const captainId = teamSnap0.exists ?
            teamSnap0.data().captainId : null;
          if (captainId) {
            await _sendUserNotification(
              captainId,
              "تعذّر إضافة اللاعب ⚠️",
              `${userName || "اللاعب"} مسجّل مع فريق ${otherName} — يجب خروجه أولاً.`,
              "joinBlockedOtherTeam",
              {teamId},
            );
          }
          return; // لا ننقل اللاعب
        }
      }
    }

    await db.runTransaction(async (tx) => {
      // ── كل القراءات أولاً ──
      const teamDoc = await tx.get(teamRef);
      const userDoc = await tx.get(userRef);
      if (!teamDoc.exists) return;
      const pid =
        userDoc.exists ? (userDoc.data().linkedPlayerId || null) : null;
      let existingPlayerRef = null;
      let existingPlayerDoc = null;
      if (pid) {
        existingPlayerRef = db.collection("players").doc(pid);
        existingPlayerDoc = await tx.get(existingPlayerRef);
      }

      // ── الكتابات ──
      const teamToken = genToken();
      // 📝 HINT AR: هوية دائمة — إن كان للّاعب سجل دائم ننقله (نحافظ على
      // careerStats)؛ وإلا ننشئ سجلاً جديداً. roster/playerCount يديرهما
      // syncRosterSummary تلقائياً.
      if (existingPlayerDoc && existingPlayerDoc.exists) {
        tx.update(existingPlayerRef, {
          currentTeamId: teamId,
          teamToken: teamToken,
          updatedAt: fv.serverTimestamp(),
        });
      } else {
        const playerRef = db.collection("players").doc();
        tx.set(playerRef, {
          name: userName || (userDoc.exists ? userDoc.data().name : "لاعب"),
          photoUrl:
            userDoc.exists ? (userDoc.data().profileImage || null) : null,
          position: "غير محدد",
          shirtNumber: null,
          preferredFoot: null,
          height: null,
          weight: null,
          status: "active",
          isStarter: true,
          currentTeamId: teamId,
          careerStats: zeroCareer(),
          claimedByUid: userId,
          createdByUid: teamDoc.data().captainId,
          teamToken: teamToken,
          createdAt: fv.serverTimestamp(),
          updatedAt: fv.serverTimestamp(),
        });
        if (userDoc.exists) {
          tx.update(userRef, {linkedPlayerId: playerRef.id});
        }
      }
    });

    // 📝 HINT AR: إغلاق بقية طلبات اللاعب المعلّقة — انضمّ لفريق آخر (بلا إشعار
    // رفض له؛ الكباتن يرونها «سجّل بفريق آخر»).
    const teamSnap = await teamRef.get();
    const teamName = teamSnap.exists ?
      (teamSnap.data().name || "الفريق") : "الفريق";
    try {
      const others = await db.collection("join_requests")
        .where("userId", "==", userId)
        .where("status", "==", "pending").get();
      const batch = db.batch();
      const notifyOps = [];
      for (const d of others.docs) {
        if (d.id === reqRef.id) continue;
        batch.update(d.ref,
          {status: "joined_elsewhere", joinedTeamName: teamName});
        // إشعار كابتن الفريق الآخر: اللاعب سجّل بفريق آخر.
        const otherTeamId = d.data().teamId;
        notifyOps.push((async () => {
          const t = await db.collection("teams").doc(otherTeamId).get();
          const cap = t.exists ? t.data().captainId : null;
          if (cap) {
            await _sendUserNotification(
              cap,
              "لاعب سجّل مع فريق آخر ℹ️",
              `${userName || "لاعب"} قدّم طلباً لفريقكم لكنه سجّل مع فريق ${teamName}.`,
              "joinedElsewhere",
              {teamId: otherTeamId},
            );
          }
        })());
      }
      await batch.commit();
      await Promise.all(notifyOps);
    } catch (e) {
      logger.warn("تعذّر إغلاق الطلبات الأخرى", {userId, error: `${e}`});
    }

    // إشعار لصاحب الطلب بعد نجاح المعاملة
    await _sendUserNotification(
      userId,
      "تم قبول طلب انضمامك ✅",
      `مرحباً بك في فريق ${teamName}! تم إنشاء بطاقة لاعبك.`,
      "joinRequestAccepted",
      {teamId},
    );
  },
);

// ============================================================================
// 5) مزامنة ملخّص التشكيلة على مستند الفريق (ترشيد الاستهلاك)
// ============================================================================
// 📝 HINT AR: نُبقي على teams.roster (ملخّص مصغّر) ليُقرأ بمستند واحد بدل قراءة
// كل لاعب. يُعاد بناؤه عند إنشاء/تعديل/حذف/انتقال لاعب. كاش متّسق نهائياً.
async function rebuildRoster(teamId) {
  if (!teamId) return;
  const snap = await db.collection("players")
    .where("currentTeamId", "==", teamId).get();
  const roster = snap.docs.map((d) => {
    const p = d.data();
    return {
      playerId: d.id,
      name: p.name,
      photoUrl: p.photoUrl || null,
      position: p.position,
      shirtNumber: p.shirtNumber != null ? p.shirtNumber : null,
    };
  });
  await db.collection("teams").doc(teamId)
    .update({roster, playerCount: roster.length});
}

exports.syncRosterSummary = onDocumentWritten("players/{id}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  const oldTeam = before ? before.currentTeamId : null;
  const newTeam = after ? after.currentTeamId : null;

  const display = ["name", "photoUrl", "position", "shirtNumber"];
  const displayChanged = !before || !after ||
    display.some((f) => JSON.stringify(before[f]) !== JSON.stringify(after[f]));

  const teams = new Set();
  if (oldTeam && oldTeam !== newTeam) teams.add(oldTeam); // ترك الفريق/انتقال
  if (newTeam && (displayChanged || oldTeam !== newTeam)) teams.add(newTeam);

  for (const t of teams) await rebuildRoster(t);
});

// ============================================================================
// 6) إرسال إشعار لمستخدم — دالة مساعدة داخلية (غير مُصدَّرة)
// ============================================================================
// 📝 HINT AR: تُنشئ مستند في `notifications/` (للـ in-app stream) وتُرسل
// FCM push إلى كل أجهزة المستخدم (fcmTokens array). الرموز المنتهية تُتجاهَل
// بصمت (لا تُنظَّف تلقائياً — يمكن إضافة ذلك لاحقاً).
async function _sendUserNotification(userId, title, body, type, data = {}) {
  const fv = admin.firestore.FieldValue;
  // 1) Firestore notification (للقراءة داخل التطبيق)
  await db.collection("notifications").add({
    userId,
    type,
    title,
    body,
    data,
    isRead: false,
    createdAt: fv.serverTimestamp(),
  });

  // 2) FCM push (نظام) إن كان للمستخدم رموز مسجّلة
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;
    const tokens = (userDoc.data().fcmTokens || []).filter((t) => !!t);
    if (tokens.length === 0) return;
    // نحوّل data إلى strings كما يشترط FCM
    const fcmData = {type};
    for (const [k, v] of Object.entries(data)) {
      fcmData[k] = String(v);
    }
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: fcmData,
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
  } catch (e) {
    logger.warn("FCM push failed", {userId, error: e.message});
  }
}

// ============================================================================
// 7) عند تغيير حالة طلب الانضمام إلى مرفوض — إشعار لصاحب الطلب
// ============================================================================
exports.onJoinRequestRejected = onDocumentUpdated(
  "join_requests/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "rejected") return;

    const {teamId, userId} = after;
    const teamSnap = await db.collection("teams").doc(teamId).get();
    const teamName = teamSnap.exists ?
      (teamSnap.data().name || "الفريق") : "الفريق";

    await _sendUserNotification(
      userId,
      "تم رفض طلب انضمامك ❌",
      `عذراً، تم رفض طلبك للانضمام إلى فريق ${teamName}`,
      "joinRequestRejected",
      {teamId},
    );
  },
);

// ============================================================================
// 7.1) عند إنشاء طلب انضمام — إشعار كابتن الفريق
// ============================================================================
// 📝 HINT AR: عند وصول طلب جديد (status=pending) نُشعر كابتن الفريق ليراجعه
// من شاشة إدارة الفريق. captainId على مستند الفريق هو uid حساب الكابتن.
exports.onJoinRequestCreated = onDocumentCreated(
  "join_requests/{id}",
  async (event) => {
    const data = event.data && event.data.data();
    if (!data || data.status !== "pending") return;

    const {teamId, userName} = data;
    if (!teamId) return;
    const teamSnap = await db.collection("teams").doc(teamId).get();
    if (!teamSnap.exists) return;
    const team = teamSnap.data();
    const captainId = team.captainId;
    if (!captainId) return;

    await _sendUserNotification(
      captainId,
      "طلب انضمام جديد 📩",
      `${userName || "لاعب"} طلب الانضمام إلى فريق ${team.name || "فريقك"}`,
      "joinRequestReceived",
      {teamId},
    );
  },
);

// ============================================================================
// 7.2) عند إنشاء طلب خروج — إشعار كابتن الفريق
// ============================================================================
exports.onReleaseRequestCreated = onDocumentCreated(
  "release_requests/{id}",
  async (event) => {
    const data = event.data && event.data.data();
    if (!data || data.status !== "pending") return;
    const {teamId, userName} = data;
    if (!teamId) return;
    const teamSnap = await db.collection("teams").doc(teamId).get();
    if (!teamSnap.exists) return;
    const captainId = teamSnap.data().captainId;
    if (!captainId) return;
    await _sendUserNotification(
      captainId,
      "طلب خروج من الفريق 🚪",
      `${userName || "لاعب"} يطلب الخروج من فريق ${teamSnap.data().name || "فريقك"}`,
      "releaseRequestReceived",
      {teamId},
    );
  },
);

// ============================================================================
// 7.3) عند بتّ طلب خروج — قبول=فكّ ارتباط، رفض=إشعار (يمكن التصعيد)
// ============================================================================
// 📝 HINT AR: القبول يفكّ ارتباط اللاعب بالفريق (currentTeamId="") مع **إبقاء**
// سجله الدائم وإحصائياته وحسابه (linkedPlayerId) — الهوية دائمة عبر الانتقالات.
// نمسح teamToken فقط. الأدمن يُنفّذ الفكّ القسري بضبط status=accepted.
exports.onReleaseRequestResolved = onDocumentUpdated(
  "release_requests/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const {playerId, teamId, userId, teamName} = after;

    if (after.status === "accepted") {
      const fv = admin.firestore.FieldValue;
      // 📝 HINT AR: لا نحذف السجل — نفكّ ارتباط الفريق فقط (syncRosterSummary
      // يُزيله من roster). careerStats و linkedPlayerId يبقيان (هوية دائمة).
      if (playerId) {
        await db.collection("players").doc(playerId).update({
          currentTeamId: "",
          teamToken: fv.delete(),
          updatedAt: fv.serverTimestamp(),
        });
      }
      await _sendUserNotification(
        userId,
        "تم فكّ ارتباطك ✅",
        `تم فكّ ارتباطك من فريق ${teamName || ""}. يمكنك الآن الانضمام لفريق آخر.`,
        "releaseAccepted",
        {teamId},
      );
    } else if (after.status === "rejected") {
      await _sendUserNotification(
        userId,
        "رُفض طلب خروجك ❌",
        `رفض كابتن ${teamName || "فريقك"} طلب خروجك. يمكنك تصعيد الطلب للإدارة.`,
        "releaseRejected",
        {teamId},
      );
    }
  },
);

// ============================================================================
// 7.4) تجميع تقييمات الحكّام — متوسط + عدد في refereeProfiles
// ============================================================================
// 📝 HINT AR: عند كتابة/تعديل تقييم حكم، نعيد حساب متوسط تقييماته وعددها من كل
// تقييماته ونكتبها في refereeProfiles/{refereeId} (حقول النظام: rating/ratingCount).
exports.onRefereeRatingWritten = onDocumentWritten(
  "referee_ratings/{id}",
  async (event) => {
    const after = event.data.after.exists ? event.data.after.data() : null;
    const before = event.data.before.exists ? event.data.before.data() : null;
    const refereeId = (after && after.refereeId) ||
      (before && before.refereeId);
    if (!refereeId) return;

    const snap = await db.collection("referee_ratings")
      .where("refereeId", "==", refereeId).get();
    let sum = 0;
    let count = 0;
    snap.forEach((d) => {
      const r = d.data().rating;
      if (typeof r === "number") {
        sum += r; count += 1;
      }
    });
    const avg = count > 0 ? Math.round((sum / count) * 10) / 10 : 0;

    await db.collection("refereeProfiles").doc(refereeId).set({
      rating: avg,
      ratingCount: count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  },
);

// ============================================================================
// 7.5) عند تقديم طلب تحكيم — إشعار كل الأدمن
// ============================================================================
exports.onRefereeApplicationCreated = onDocumentCreated(
  "referee_applications/{id}",
  async (event) => {
    const data = event.data && event.data.data();
    if (!data || data.status !== "pending") return;
    const admins = await db.collection("users")
      .where("role", "==", "admin").get();
    await Promise.all(admins.docs.map((d) => _sendUserNotification(
      d.id,
      "طلب تحكيم جديد 🧑‍⚖️",
      `${data.userName || "مستخدم"} يطلب التحكيم في بطولة ${data.tournamentName || ""}`,
      "refereeApplicationReceived",
      {tournamentId: data.tournamentId || ""},
    )));
  },
);

// ============================================================================
// 7.6) عند بتّ طلب تحكيم — موافقة=منح صفة حكم + إشعار المنظّم، رفض=إشعار
// ============================================================================
exports.onRefereeApplicationResolved = onDocumentUpdated(
  "referee_applications/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    const {userId, userName, tournamentId, tournamentName, organizerUid} =
      after;

    if (after.status === "approved") {
      // منح صفة الحكم (Custom Claim + مرآة Firestore).
      try {
        const user = await admin.auth().getUser(userId);
        const claims = Object.assign({}, user.customClaims || {});
        claims.referee = true;
        await admin.auth().setCustomUserClaims(userId, claims);
      } catch (e) {
        logger.warn("تعذّر منح صفة الحكم", {userId, error: `${e}`});
      }
      const fv = admin.firestore.FieldValue;
      await db.collection("users").doc(userId).set({
        adminPermissions: fv.arrayUnion("referee"),
        updatedAt: fv.serverTimestamp(),
      }, {merge: true});

      // إشعار مقدّم الطلب + المنظّم.
      await _sendUserNotification(
        userId,
        "تمت الموافقة على طلب التحكيم ✅",
        `أصبحت حكماً. سيضيفك منظّم بطولة ${tournamentName || ""} للمباريات.`,
        "refereeApplicationApproved",
        {tournamentId: tournamentId || ""},
      );
      if (organizerUid) {
        await _sendUserNotification(
          organizerUid,
          "حكم جاهز لبطولتك 🧑‍⚖️",
          `وافق الأدمن على تحكيم ${userName || "مستخدم"} في ${tournamentName || "بطولتك"}. عيّنه على المباريات.`,
          "refereeReadyForTournament",
          {tournamentId: tournamentId || ""},
        );
      }
    } else if (after.status === "rejected") {
      await _sendUserNotification(
        userId,
        "طلب التحكيم مرفوض ❌",
        `عذراً، رُفض طلبك للتحكيم في ${tournamentName || "البطولة"}.`,
        "refereeApplicationRejected",
        {tournamentId: tournamentId || ""},
      );
    }
  },
);

// ============================================================================
// 8) حذف الحساب نهائياً (مطلوب لمتجري Apple وGoogle) — callable
// ============================================================================
// 📝 HINT AR: يحذف بيانات المستخدم الشخصية + حساب المصادقة. يرفض إن كان
// المستخدم كابتن فريق (لتجنّب فرق يتيمة) — يطلب حذف/نقل الفريق أولاً.
// فكّ ربط سجل اللاعب (claimedByUid) يُبقي السجل الكروي للفريق لكن بلا حساب.
exports.deleteMyAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }
  const uid = request.auth.uid;
  const fv = admin.firestore.FieldValue;

  // 1) منع الحذف إن كان كابتن فريق (فرق يتيمة).
  const captainTeams = await db.collection("teams")
    .where("captainId", "==", uid).limit(1).get();
  if (!captainTeams.empty) {
    throw new HttpsError("failed-precondition",
      "أنت كابتن فريق — احذف فريقك أو انقل الكابتنية قبل حذف الحساب.");
  }

  // 2) فكّ ربط سجل اللاعب المرتبط (إن وُجد).
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  const linkedPlayerId = userDoc.exists ?
    userDoc.data().linkedPlayerId : null;

  const batch = db.batch();
  if (linkedPlayerId) {
    batch.update(db.collection("players").doc(linkedPlayerId), {
      claimedByUid: fv.delete(),
      updatedAt: fv.serverTimestamp(),
    });
  }

  // 3) حذف طلبات الانضمام التي أنشأها المستخدم.
  const reqs = await db.collection("join_requests")
    .where("userId", "==", uid).get();
  reqs.forEach((d) => batch.delete(d.ref));

  // 4) حذف مستند المستخدم.
  batch.delete(userRef);
  await batch.commit();

  // 5) حذف حساب المصادقة (آخر خطوة).
  await admin.auth().deleteUser(uid);

  return {success: true};
});

// ============================================================================
// 9) إجراءات الأدمن على البلاغات — رد / حظر / تنبيه / تقييم سلبي (R1)
// ============================================================================
// 📝 HINT AR: للأدمن فقط. يطبّق العقوبة على حساب/فريق/لاعب المُبلَّغ عنه ثم
// يحدّث البلاغ (الرد + الإجراء + الحالة=مُراجَع). الحقول المحسوبة (ratingPoints/
// careerStats) تُكتب هنا عبر Admin SDK حصراً (لا من العميل).
exports.moderateReport = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    const isAdminDoc = request.auth && (await db.collection("users")
      .doc(request.auth.uid).get()).data() &&
      (await db.collection("users").doc(request.auth.uid).get())
        .data().role === "admin";
    if (!isAdminDoc) {
      throw new HttpsError("permission-denied", "هذه العملية للأدمن فقط.");
    }
  }
  const {reportId, action, adminReply, ratingPenalty} = request.data || {};
  const allowed = ["ban", "warn", "negativeRating", "review", "dismiss"];
  if (!reportId || !allowed.includes(action)) {
    throw new HttpsError("invalid-argument", "بيانات غير صالحة.");
  }

  const reportRef = db.collection("reports").doc(reportId);
  const reportDoc = await reportRef.get();
  if (!reportDoc.exists) {
    throw new HttpsError("not-found", "البلاغ غير موجود.");
  }
  const report = reportDoc.data();
  const fv = admin.firestore.FieldValue;

  // تحديد مجموعة الهدف من نوعه.
  const collByType = {player: "players", team: "teams", user: "users"};
  const coll = collByType[report.targetType];
  const targetRef = (coll && report.targetId) ?
    db.collection(coll).doc(report.targetId) : null;

  // تطبيق العقوبة على الهدف.
  if (targetRef && action !== "review" && action !== "dismiss") {
    const penalty = (typeof ratingPenalty === "number" &&
      ratingPenalty > 0) ? ratingPenalty : 25;
    if (action === "ban") {
      await targetRef.set({
        banned: true, bannedAt: fv.serverTimestamp(),
      }, {merge: true});
    } else if (action === "warn") {
      await targetRef.set({
        warnings: fv.increment(1), lastWarnedAt: fv.serverTimestamp(),
      }, {merge: true});
    } else if (action === "negativeRating") {
      if (report.targetType === "team") {
        await targetRef.set({
          ratingPoints: fv.increment(-penalty),
        }, {merge: true});
      } else if (report.targetType === "player") {
        // التقييم داخل careerStats — نقرأ ونطرح بحدّ أدنى صفر.
        const pDoc = await targetRef.get();
        const cs = (pDoc.exists && pDoc.data().careerStats) || {};
        const cur = cs.rating || 0;
        const next = Math.max(0, cur - (penalty / 10));
        await targetRef.set({
          careerStats: Object.assign({}, cs, {rating: next}),
        }, {merge: true});
      }
    }
  }

  // تحديث البلاغ.
  const newStatus = action === "dismiss" ? "dismissed" : "reviewed";
  await reportRef.update({
    status: newStatus,
    moderationAction: action,
    adminReply: adminReply || null,
    moderatedBy: request.auth.uid,
    moderatedAt: fv.serverTimestamp(),
  });

  return {success: true};
});

// ============================================================================
// 17) تحدّيات الفرق (المرحلة 7) — إشعارات التقديم والقبول
// ============================================================================
// 📝 HINT AR: عند تقدّم فريق جديد على تحدٍّ (نمو applicantCaptainIds) →
// إشعار صاحب الطلب. الطرف الآخر لا يكتب إشعار غيره (القواعد تمنعه) — لذا CF.
exports.onChallengeApplied = onDocumentUpdated(
  "challenges/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    const beforeIds = before.applicantCaptainIds || [];
    const afterIds = after.applicantCaptainIds || [];
    if (afterIds.length <= beforeIds.length) return; // لا متقدّم جديد

    const newIds = afterIds.filter((x) => !beforeIds.includes(x));
    const applicant = (after.applicants || [])
      .find((a) => newIds.includes(a.captainId));
    const teamName = applicant ? applicant.teamName : "فريق";
    await _sendUserNotification(
      after.requesterCaptainId,
      "طلب تحدٍّ جديد",
      `فريق ${teamName} وافق على تحدّي فريقك «${after.requesterTeamName}»`,
      "challenge_applied",
      {challengeId: event.params.id},
    );
  },
);

// 📝 HINT AR: عند قبول التحدّي (status → matched) → إشعار الفريق المختار
// بفتح المحادثة (chatId مُمرَّر في الإشعار).
exports.onChallengeMatched = onDocumentUpdated(
  "challenges/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === "matched" || after.status !== "matched") return;
    if (!after.matchedCaptainId) return;
    await _sendUserNotification(
      after.matchedCaptainId,
      "تم قبول تحدّيك 🎉",
      `فريق ${after.requesterTeamName} اختارك للتحدّي — افتح المحادثة للاتفاق`,
      "challenge_matched",
      {challengeId: event.params.id, chatId: after.chatId || ""},
    );
  },
);

// ============================================================================
// 18) الاشتراكات (المرحلة 8) — تفعيل بالكود + التجربة المجانية
// ============================================================================
// 📝 HINT AR: تفعيل اشتراك الكابتن بكود. حقول الاشتراك على users تكتبها CF فقط
// (جدار المصداقية). تحقّق خادمي + rate-limit (قفل بعد 5 محاولات خاطئة/ساعة على
// مستند المستخدم) + معاملة ذرّية (يعلّم الكود مستخدماً ويمدّد الاشتراك) + سجل تدقيق.
exports.redeemActivationCode = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل الدخول أولاً");
  const code = String((request.data && request.data.code) || "")
    .toUpperCase().trim();
  if (!code) throw new HttpsError("invalid-argument", "أدخل الكود");

  const fv = admin.firestore.FieldValue;
  const Timestamp = admin.firestore.Timestamp;
  const userRef = db.collection("users").doc(uid);
  const codeRef = db.collection("activation_codes").doc(code);

  const userSnap = await userRef.get();
  const u = userSnap.exists ? userSnap.data() : {};

  // قفل المحاولات (rate-limit).
  const lockUntil = u.activationLockUntil ?
    u.activationLockUntil.toDate() : null;
  if (lockUntil && lockUntil > new Date()) {
    throw new HttpsError(
      "resource-exhausted", "تجاوزت عدد المحاولات — حاول بعد قليل");
  }

  const recordFailure = async (reason) => {
    await db.collection("activation_attempts").add({
      userId: uid, code, success: false, reason,
      createdAt: fv.serverTimestamp(),
    });
    const count = (u.activationFailedCount || 0) + 1;
    const updates = {activationFailedCount: count};
    if (count >= 5) {
      updates.activationLockUntil =
        Timestamp.fromMillis(Date.now() + 3600000);
      updates.activationFailedCount = 0;
    }
    await userRef.set(updates, {merge: true});
  };

  const codeSnap = await codeRef.get();
  if (!codeSnap.exists) {
    await recordFailure("كود غير موجود");
    throw new HttpsError("not-found", "الكود غير موجود — تأكّد من كتابته");
  }
  const c = codeSnap.data();
  if (c.isLocked) throw new HttpsError("permission-denied", "هذا الكود مقفل");
  if (c.isUsed) {
    await recordFailure("مستخدم");
    throw new HttpsError("already-exists", "هذا الكود مُستخدم بالفعل");
  }

  const durationMonths = c.durationMonths || 1;
  let expiresMillis = 0;

  await db.runTransaction(async (tx) => {
    const freshCode = await tx.get(codeRef);
    const freshUser = await tx.get(userRef);
    if (!freshCode.exists || freshCode.data().isUsed) {
      throw new HttpsError("already-exists", "هذا الكود مُستخدم بالفعل");
    }
    const now = new Date();
    const cur = freshUser.exists && freshUser.data().subscriptionExpiresAt ?
      freshUser.data().subscriptionExpiresAt.toDate() : null;
    const base = (cur && cur > now) ? cur : now; // يمدّد من الانتهاء إن نشطاً
    const newExpiry = new Date(base);
    newExpiry.setMonth(newExpiry.getMonth() + durationMonths);
    expiresMillis = newExpiry.getTime();

    tx.update(codeRef, {
      isUsed: true,
      usedBy: uid,
      usedByName: (freshUser.data() || {}).name || "",
      usedAt: fv.serverTimestamp(),
    });
    tx.set(userRef, {
      subscriptionStatus: "active",
      subscriptionExpiresAt: Timestamp.fromDate(newExpiry),
      subscriptionActivatedAt: fv.serverTimestamp(),
      activationFailedCount: 0,
    }, {merge: true});
  });

  await db.collection("activation_attempts").add({
    userId: uid, code, success: true, reason: "تم التفعيل",
    createdAt: fv.serverTimestamp(),
  });
  return {durationMonths, expiresAt: expiresMillis};
});

// 📝 HINT AR: يمنح التجربة المجانية للكابتن مرة واحدة (idempotent) — يُستدعى عند
// فتح بطاقة الاشتراك. لا يمنح إن كان للكابتن اشتراك بالفعل أو لم يكن كابتناً.
exports.startTrialIfEligible = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل الدخول أولاً");
  const fv = admin.firestore.FieldValue;
  const Timestamp = admin.firestore.Timestamp;
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) return {granted: false};
  const u = snap.data();
  if (u.role !== "captain") return {granted: false};
  if (u.subscriptionExpiresAt) return {granted: false};

  let trialDays = 14;
  try {
    const cfg = await db.collection("settings").doc("subscription").get();
    if (cfg.exists && cfg.data().freeTrialDays) {
      trialDays = cfg.data().freeTrialDays;
    }
  } catch (e) {
    logger.warn("freeTrialDays read failed", {error: e.message});
  }

  const expiry = Timestamp.fromMillis(Date.now() + trialDays * 86400000);
  await userRef.set({
    subscriptionStatus: "free_trial",
    subscriptionExpiresAt: expiry,
    subscriptionActivatedAt: fv.serverTimestamp(),
  }, {merge: true});
  return {granted: true, expiresAt: expiry.toMillis(), trialDays};
});

// ============================================================================
// 21) تشكيلات البطولة (بند 8) — إشعار الكباتن بإنشاء البطولة + إشعارات المراجعة
// ============================================================================

// 📝 HINT AR: عند إنشاء بطولة — يُشعَر كابتن كل فريق مشارك ليُدخل تشكيلته.
exports.onTournamentCreated = onDocumentCreated(
  "tournaments/{id}",
  async (event) => {
    const t = event.data && event.data.data();
    if (!t) return;
    const teamIds = t.teamIds || [];
    for (const teamId of teamIds) {
      try {
        const teamDoc = await db.collection("teams").doc(teamId).get();
        if (!teamDoc.exists) continue;
        const captainId = teamDoc.data().captainId;
        if (!captainId) continue;
        await _sendUserNotification(
          captainId,
          "بطولة جديدة ⚽",
          `فريقك مشارك في بطولة «${t.name}» — أدخل تشكيلتك للمراجعة`,
          "tournament_created",
          {tournamentId: event.params.id},
        );
      } catch (e) {
        logger.warn("notify captain failed", {teamId, error: e.message});
      }
    }
  },
);

// 📝 HINT AR: عند كتابة تشكيلة — إن صارت pending (إرسال الكابتن) يُشعَر المنظّم؛
// وإن صارت approved/rejected (مراجعة المنظّم) يُشعَر الكابتن.
exports.onTournamentLineupWritten = onDocumentWritten(
  "tournament_lineups/{id}",
  async (event) => {
    const after = event.data.after.exists ? event.data.after.data() : null;
    if (!after) return;
    const before = event.data.before.exists ? event.data.before.data() : null;
    const status = after.status;

    // إرسال الكابتن → إشعار المنظّم.
    if (status === "pending" && (!before || before.status !== "pending")) {
      try {
        const t = await db.collection("tournaments")
          .doc(after.tournamentId).get();
        if (t.exists) {
          await _sendUserNotification(
            t.data().organizerUid,
            "تشكيلة بانتظار المراجعة",
            `أرسل فريق «${after.teamName}» تشكيلته في بطولة ${t.data().name}`,
            "lineup_submitted",
            {tournamentId: after.tournamentId},
          );
        }
      } catch (e) {
        logger.warn("notify organizer failed", {error: e.message});
      }
    }

    // مراجعة المنظّم → إشعار الكابتن.
    if ((status === "approved" || status === "rejected") &&
        (!before || before.status !== status)) {
      const msg = status === "approved" ?
        "قُبلت تشكيلة فريقك في البطولة ✅" :
        `رُفضت تشكيلة فريقك — ${after.reviewNote || "راجعها وأعد الإرسال"}`;
      await _sendUserNotification(
        after.captainId,
        "مراجعة التشكيلة",
        msg,
        "lineup_reviewed",
        {tournamentId: after.tournamentId, teamId: after.teamId},
      );
    }
  },
);

// ============================================================================
// 22) عند إنشاء مستخدم بدور «حكم» — منح صفة الحكم + إنشاء ملف الحكم العام (D)
// ============================================================================
// 📝 HINT AR: التسجيل المباشر كحكم يُنشئ مستند users بـ role='referee'. هذه الدالة
// تمنحه صفة الحكم (Custom Claim + adminPermissions ليظهر في getReferees) وتُنشئ
// refereeProfiles/{uid} (صفحته العامة). idempotent (set/merge + arrayUnion).
exports.onUserCreated = onDocumentCreated("users/{uid}", async (event) => {
  const data = event.data && event.data.data();
  if (!data || data.role !== "referee") return;
  const uid = event.params.uid;
  const fv = admin.firestore.FieldValue;

  try {
    const user = await admin.auth().getUser(uid);
    const claims = Object.assign({}, user.customClaims || {});
    claims.referee = true;
    await admin.auth().setCustomUserClaims(uid, claims);
  } catch (e) {
    logger.warn("تعذّر منح صفة الحكم عند التسجيل", {uid, error: `${e}`});
  }

  await db.collection("users").doc(uid).set({
    adminPermissions: fv.arrayUnion("referee"),
    updatedAt: fv.serverTimestamp(),
  }, {merge: true});

  await db.collection("refereeProfiles").doc(uid).set({
    name: data.name || "حكم",
    photoUrl: data.profileImage || null,
    city: data.city || null,
    rating: 0,
    ratingCount: 0,
    createdAt: fv.serverTimestamp(),
    updatedAt: fv.serverTimestamp(),
  }, {merge: true});
});

// ============================================================================
// 23) تقييم الحكم — callable مع فرض خادمي (D، النقطتان 9 و10)
// ============================================================================
// 📝 HINT AR: التقييم محصور بـ: منظّم البطولة، أو الأدمن، أو كابتن أحد فريقَي
// المباراة فقط؛ مرة واحدة (معرّف matchId_raterId)؛ والحكم لا يقيّم نفسه. القاعدة
// تمنع كتابة العميل المباشرة (referee_ratings) فالكتابة هنا عبر Admin SDK فقط،
// ثم onRefereeRatingWritten يجمّع المتوسط في refereeProfiles.
exports.rateReferee = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل الدخول أولاً");
  const {matchId, refereeId, rating} = request.data || {};
  if (!matchId || !refereeId) {
    throw new HttpsError("invalid-argument", "بيانات غير صالحة");
  }
  const r = Number(rating);
  if (!Number.isInteger(r) || r < 1 || r > 5) {
    throw new HttpsError("invalid-argument", "التقييم من 1 إلى 5");
  }
  if (uid === refereeId) {
    throw new HttpsError("permission-denied", "لا يمكنك تقييم نفسك");
  }

  const matchSnap = await db.collection("matches").doc(matchId).get();
  if (!matchSnap.exists) {
    throw new HttpsError("not-found", "المباراة غير موجودة");
  }
  const m = matchSnap.data();
  if (m.refereeId !== refereeId) {
    throw new HttpsError("invalid-argument", "هذا الحكم ليس حكم المباراة");
  }
  if (m.resultConfirmed !== true) {
    throw new HttpsError("failed-precondition", "المباراة لم تنتهِ بعد");
  }

  // ── فرض الصلاحية: أدمن / منظّم البطولة / كابتن أحد الفريقين ──
  let allowed = request.auth.token && request.auth.token.admin === true;
  if (!allowed && m.tournamentId) {
    const t = await db.collection("tournaments").doc(m.tournamentId).get();
    if (t.exists && t.data().organizerUid === uid) allowed = true;
  }
  if (!allowed) {
    for (const tid of [m.homeTeamId, m.awayTeamId]) {
      if (!tid) continue;
      const teamSnap = await db.collection("teams").doc(tid).get();
      if (teamSnap.exists && teamSnap.data().captainId === uid) {
        allowed = true;
        break;
      }
    }
  }
  if (!allowed) {
    // fallback: دور أدمن في Firestore.
    const u = await db.collection("users").doc(uid).get();
    if (u.exists && u.data().role === "admin") allowed = true;
  }
  if (!allowed) {
    throw new HttpsError(
      "permission-denied",
      "التقييم للمنظّم أو الأدمن أو كابتن الفريق فقط");
  }

  // ── مرة واحدة فقط (لا تعديل) ──
  const ratingRef = db.collection("referee_ratings").doc(`${matchId}_${uid}`);
  const existing = await ratingRef.get();
  if (existing.exists) {
    throw new HttpsError("already-exists", "قيّمت هذا الحكم مسبقاً");
  }
  await ratingRef.set({
    refereeId,
    matchId,
    raterId: uid,
    rating: r,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true};
});

// ============================================================================
// 24) تذكير كابتن بإرسال تشكيلته (الوجبة 7 — بند 2) — للمنظّم/الأدمن
// ============================================================================
// 📝 HINT AR: قاعدة الإشعارات تمنع العميل من إشعار غيره، فالتذكير عبر CF. يتحقق
// أن المستدعي منظّم البطولة أو أدمن ثم يُرسل إشعاراً لكابتن الفريق المعنيّ.
exports.remindLineup = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل الدخول أولاً");
  const {tournamentId, teamId, message} = request.data || {};
  if (!tournamentId || !teamId) {
    throw new HttpsError("invalid-argument", "بيانات غير صالحة");
  }
  const tDoc = await db.collection("tournaments").doc(tournamentId).get();
  if (!tDoc.exists) throw new HttpsError("not-found", "البطولة غير موجودة");
  const isAdmin = request.auth.token && request.auth.token.admin === true;
  if (!isAdmin && tDoc.data().organizerUid !== uid) {
    throw new HttpsError("permission-denied", "للمنظّم أو الأدمن فقط");
  }
  const teamDoc = await db.collection("teams").doc(teamId).get();
  if (!teamDoc.exists) throw new HttpsError("not-found", "الفريق غير موجود");
  const captainId = teamDoc.data().captainId;
  if (!captainId) throw new HttpsError("failed-precondition", "لا كابتن للفريق");

  const body = (message && String(message).trim()) ||
    `يرجى إرسال تشكيلة فريقك في بطولة «${tDoc.data().name || ""}» — قد ` +
    "يُقصى الفريق أو يخسر مباراته القادمة 3-0 إن لم تُرسَل.";
  await _sendUserNotification(
    captainId,
    "تذكير: أرسل تشكيلتك ⚠️",
    body,
    "lineup_reminder",
    {tournamentId, teamId},
  );
  return {success: true};
});
