import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    content = f.read()

# Replace _myTeamTab
my_team_tab_old = """  // ── تبويب «فريقي» ──────────────────────────────────────────────────────
  Widget _myTeamTab(UserModel user, bool isDark) {
    return FutureBuilder<TeamModel?>(
      future: _myTeam(user),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 1, tileHeight: 200);
        }
        final team = snap.data;
        if (team == null) {
          return ToobaEmptyState(
            icon: Icons.shield_outlined,
            title: user.role == 'captain'
                ? 'لا تملك فريقاً بعد'
                : 'لست مسجّلاً في أي فريق',
            subtitle: user.role == 'captain'
                ? 'أسّس فريقك بزر «تأسيس فريق» أدناه'
                : 'انضمّ إلى فريق من تبويب «الفرق الشعبية»',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshMyTeam(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_myTeamCard(team, user, isDark)],
          ),
        );
      },
    );
  }"""

my_team_tab_new = """  // ── تبويب «فريقي» ──────────────────────────────────────────────────────
  Widget _myTeamTab(UserModel user, bool isDark) {
    return FutureBuilder<TeamModel?>(
      future: _myTeam(user),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 1, tileHeight: 200);
        }
        final team = snap.data;
        if (team == null) {
          return _buildNoTeamState(user, isDark);
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshMyTeam(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [_myTeamCard(team, user, isDark)],
          ),
        );
      },
    );
  }

  Widget _buildNoTeamState(UserModel user, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // 📝 HINT AR: صورة الملعب
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13261C) : const Color(0xFFE6F9EE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00D166).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // رسمة الملعب المبسطة
                Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 1.5,
                          height: 120,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
                const Center(child: Text('⚽', style: TextStyle(fontSize: 40))),
                Positioned(
                  bottom: 14,
                  child: Text('ملعبك ينتظرك',
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('ليس لديك فريق بعد؟',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(
              user.role == 'captain'
                  ? 'أسّس فريقك وانضم للبطولات المحلية\\nفي منطقتك الآن'
                  : 'انضم إلى فريق موجود وانطلق نحو\\nالبطولات المحلية',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          if (user.role == 'captain') ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  ToobaRoute.to(const CreateTeamScreen()),
                ).then((_) {
                  _refreshMyTeam();
                  context.read<TeamCubit>().fetchTeams();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D166), Color(0xFF00924A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D166).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('⚽ أسّس فريقك الآن',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: () {
              DefaultTabController.of(context).animateTo(1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1826) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[300]!),
              ),
              alignment: Alignment.center,
              child: Text('انضم إلى فريق موجود',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }"""

content = content.replace(my_team_tab_old, my_team_tab_new)

# Now we rewrite _myTeamCard entirely.
old_my_team_card_pattern = r"Widget _myTeamCard\(TeamModel team, UserModel user, bool isDark\) \{.*?(?=\/\/ 📝 HINT AR: يعرض في «فريقي» تنبيه رفض الخروج \+ زر التصعيد للإدارة\.)"
new_my_team_card = """Widget _myTeamCard(TeamModel team, UserModel user, bool isDark) {
    final theme = Theme.of(context);
    final isCaptain = team.captainId == user.id;
    return Column(
      children: [
        // 📝 HINT AR: بانر الفريق العلوي
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1A3050), Color(0xFF0D1826)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE6F0FF), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
          child: Column(
            children: [
              Hero(
                tag: 'team_logo_${team.id}',
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4A800).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: isDark ? const Color(0xFF1A3050) : Colors.white,
                    image: team.logoUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(team.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: team.logoUrl == null
                      ? Center(
                          child: Text('🦅', style: const TextStyle(fontSize: 44)))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(team.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    team.area != null && team.area!.isNotEmpty
                        ? '${team.city} • ${team.area}'
                        : team.city,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // الإحصائيات باللون الذهبي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBadge('تقييم', team.ratingPoints.toString(), true),
                  const SizedBox(width: 12),
                  _statBadge('لعب', team.stats.played.toString(), false),
                  const SizedBox(width: 12),
                  _statBadge('فاز', team.stats.wins.toString(), false),
                  const SizedBox(width: 12),
                  _statBadge('بطولات', team.badges.length.toString(), false),
                ],
              ),
            ],
          ),
        ),
        
        // 📝 HINT AR: أزرار الإجراءات السريعة
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    ToobaRoute.to(BlocProvider(
                      create: (ctx) => TeamCubit(
                        ctx.read<TeamRepository>(),
                        ctx.read<PlayerRepository>(),
                      ),
                      child: TeamDetailsScreen(teamId: team.id),
                    )),
                  ).then((_) => _refreshMyTeam()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A3050) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isCaptain ? 'إدارة الفريق' : 'عرض الفريق',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
              ),
              if (isCaptain) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context, ToobaRoute.to(const ChallengesScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A3050) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'التحديات',
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 📝 HINT AR: التشكيلة (اللاعبون)
        if (team.roster.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('التشكيلة',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87)),
                Text('${team.playerCount} لاعب',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: team.roster.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = team.roster[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1826) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF1A3050) : Colors.grey[200],
                      backgroundImage: player.photoUrl != null
                          ? CachedNetworkImageProvider(player.photoUrl!)
                          : null,
                      child: player.photoUrl == null
                          ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(player.position,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54)),
                        ],
                      ),
                    ),
                    if (player.shirtNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          player.shirtNumber.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        if (!isCaptain &&
            user.linkedPlayerId != null &&
            user.linkedPlayerId!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _releaseStatusInMyTeam(user.linkedPlayerId!),
          ),
      ],
    );
  }

  Widget _statBadge(String title, String value, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: isPrimary ? const Color(0xFFD4A800) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(title,
              style: TextStyle(
                  color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.8) : Colors.white54,
                  fontSize: 10)),
        ],
      ),
    );
  }

  """

content = re.sub(old_my_team_card_pattern, new_my_team_card, content, flags=re.DOTALL)

with open('lib/presentation/screens/teams/teams_screen.dart', 'w') as f:
    f.write(content)

