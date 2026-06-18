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
function updateStanding(standings, teamId, gf, ga, o, sign, rule) {
  let e = standings.find((s) => s.teamId === teamId);
  if (!e) {
    e = {teamId, played: 0, won: 0, drawn: 0, lost: 0,
      gf: 0, ga: 0, gd: 0, points: 0};
    standings.push(e);
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
// 📝 HINT AR: فرز الترتيب: النقاط ← فارق الأهداف ← الأهداف المسجّلة.
function sortStandings(s) {
  s.sort((a, b) => (b.points - a.points) || (b.gd - a.gd) || (b.gf - a.gf));
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
      const hasStandings = tournDoc && tournDoc.exists &&
          tournDoc.data().type === "league";
      const standings = hasStandings ?
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
          updateStanding(standings, homeTeamId, hs, as, ho, sign, rule);
          updateStanding(standings, awayTeamId, as, hs, ao, sign, rule);
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

    // ── كشف بطل البطولة (T3) ──────────────────────────────────────────
    // 📝 HINT AR: بعد تأكيد نتيجة، إن أصبحت كل مباريات البطولة مؤكّدة نُنهيها
    // ونحدّد الفائز (متصدّر الترتيب). idempotent: ضبط منتهية مراراً غير ضار.
    if (desired && tournamentId) {
      try {
        await finalizeTournamentIfDone(tournamentId);
      } catch (e) {
        logger.warn("تعذّر كشف بطل البطولة", {tournamentId, error: `${e}`});
      }
    }
  },
);

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

  // الفائز: متصدّر الترتيب (للدوري) وإلا فائز المباراة الأخيرة (إقصائي).
  let winnerTeamId = null;
  const standings = t.standings || [];
  if (standings.length > 0) {
    winnerTeamId = standings[0].teamId || null;
  } else {
    // إقصائي: فائز آخر مباراة (الأعلى round).
    let last = null;
    matchesSnap.docs.forEach((d) => {
      const m = d.data();
      if (!last || (m.round || 0) > (last.round || 0)) last = m;
    });
    if (last) {
      winnerTeamId = (last.homeScore >= last.awayScore) ?
        last.homeTeamId : last.awayTeamId;
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
// 4) عند قبول طلب انضمام: إنشاء سجل لاعب مرتبط بحساب صاحب الطلب
// ============================================================================
exports.onJoinRequestAccepted = onDocumentUpdated(
  "join_requests/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "accepted") return;

    const {teamId, userId, userName} = after;
    const teamRef = db.collection("teams").doc(teamId);
    const userRef = db.collection("users").doc(userId);
    const playerRef = db.collection("players").doc(); // معرّف جديد

    await db.runTransaction(async (tx) => {
      const [teamDoc, userDoc] = await Promise.all([
        tx.get(teamRef), tx.get(userRef),
      ]);
      if (!teamDoc.exists) return;
      const fv = admin.firestore.FieldValue;
      // 📝 HINT AR: التشكيلة (roster) و playerCount يديرهما syncRosterSummary
      // تلقائياً عند إنشاء هذا السجل — فلا نلمسهما هنا لتجنّب التضارب.
      tx.set(playerRef, {
        name: userName || (userDoc.exists ? userDoc.data().name : "لاعب"),
        photoUrl: userDoc.exists ? (userDoc.data().profileImage || null) : null,
        position: "غير محدد",
        shirtNumber: null,
        preferredFoot: null,
        height: null,
        weight: null,
        status: "active",
        currentTeamId: teamId,
        careerStats: zeroCareer(),
        claimedByUid: userId,
        createdByUid: teamDoc.data().captainId,
        createdAt: fv.serverTimestamp(),
        updatedAt: fv.serverTimestamp(),
      });
      if (userDoc.exists) {
        tx.update(userRef, {linkedPlayerId: playerRef.id});
      }
    });

    // إشعار لصاحب الطلب بعد نجاح المعاملة
    const teamSnap = await teamRef.get();
    const teamName = teamSnap.exists ?
      (teamSnap.data().name || "الفريق") : "الفريق";
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
