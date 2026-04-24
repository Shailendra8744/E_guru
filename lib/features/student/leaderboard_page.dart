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
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(leaderboardProvider),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No rankings available yet.'));
          }

          return Column(
            children: [
              // Podium for top 1-3
              if (students.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: students.length > 3 ? students.length - 3 : 0,
                    itemBuilder: (context, index) {
                      final student = students[index + 3];
                      final rank = index + 4;
                      return _LeaderboardTile(
                        rank: rank,
                        name: student['full_name'],
                        xp: student['xp'] ?? 0,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
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
    final color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey.shade400 : Colors.brown.shade400);
    
    return Column(
      children: [
        if (isKing)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: isKing ? 45 : 35,
          backgroundColor: color,
          child: CircleAvatar(
            radius: isKing ? 41 : 32,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name.split(' ')[0],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isKing ? 16 : 14,
          ),
        ),
        Text(
          '$xp XP',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#$rank',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.xp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
