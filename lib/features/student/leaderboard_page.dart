import 'package:e_guru/core/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/leaderboard');
  return (res['items'] as List<dynamic>?) ?? [];
});

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final user = ref.watch(authSessionProvider).value;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Top Learners', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(leaderboardProvider),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: leaderboardAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No rankings available yet.'));
          }

          // Find current user's rank
          Map<String, dynamic>? currentUserData;
          int currentUserRank = 0;
          if (user != null) {
            for (int i = 0; i < students.length; i++) {
              if (students[i]['id'] == user.id) {
                currentUserData = students[i];
                currentUserRank = i + 1;
                break;
              }
            }
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Gradient Header with Podium
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 60, 20, 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838), const Color(0xFF1A1040)]
                            : [theme.colorScheme.primary, const Color(0xFF5C6BC0), const Color(0xFF7E57C2)],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Rank 2
                        if (students.length >= 2)
                          _PodiumItem(
                            name: students[1]['full_name'],
                            xp: students[1]['xp'] ?? 0,
                            rank: 2,
                            isDark: isDark,
                          )
                        else
                          const Spacer(),
                        
                        // Rank 1
                        _PodiumItem(
                          name: students[0]['full_name'],
                          xp: students[0]['xp'] ?? 0,
                          rank: 1,
                          isDark: isDark,
                          isKing: true,
                        ),
                        
                        // Rank 3
                        if (students.length >= 3)
                          _PodiumItem(
                            name: students[2]['full_name'],
                            xp: students[2]['xp'] ?? 0,
                            rank: 3,
                            isDark: isDark,
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                  
                  // List for the rest (4th place onwards)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: students.length > 3 ? students.length - 3 : 0,
                      itemBuilder: (context, index) {
                        final student = students[index + 3];
                        final rank = index + 4;
                        final isCurrentUser = user != null && student['id'] == user.id;
                        return _LeaderboardTile(
                          rank: rank,
                          name: student['full_name'],
                          xp: student['xp'] ?? 0,
                          isDark: isDark,
                          isHighlight: isCurrentUser,
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Sticky "Your Rank" Footer
              if (currentUserData != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2838) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#$currentUserRank',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${currentUserData['full_name']}&background=random'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Your Ranking',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  currentUserData['full_name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${currentUserData['xp']} XP',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final String name;
  final int xp;
  final int rank;
  final bool isDark;
  final bool isKing;

  const _PodiumItem({
    required this.name,
    required this.xp,
    required this.rank,
    required this.isDark,
    this.isKing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey.shade300 : Colors.orange.shade300);
    
    return Column(
      children: [
        if (isKing)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 36),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withAlpha(100), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: CircleAvatar(
            radius: isKing ? 45 : 35,
            backgroundColor: color.withAlpha(50),
            child: CircleAvatar(
              radius: isKing ? 40 : 31,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name.split(' ')[0],
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isKing ? 16 : 14,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          '$xp XP',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: color.withAlpha(100), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Text(
            '#$rank',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final bool isDark;
  final bool isHighlight;

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.xp,
    required this.isDark,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight 
            ? theme.colorScheme.primary.withAlpha(isDark ? 30 : 15)
            : (isDark ? Colors.white.withAlpha(10) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight 
              ? theme.colorScheme.primary.withAlpha(50)
              : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade100),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            alignment: Alignment.centerLeft,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isHighlight ? theme.colorScheme.primary : Colors.grey.shade500,
                fontSize: 15,
              ),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ),
          Text(
            '$xp XP',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
