import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    c = f.read()

c = c.replace(
    "return GestureDetector(",
    "return GestureDetector("
)

# Wait, let's just find the exact block and replace it correctly.
# The block is:
# return GestureDetector(
#                 onTap: () {
#     // We must fetch the PlayerModel first
#     showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
#     context.read<PlayerRepository>().getPlayerById(player.id).then((pModel) {
#         Navigator.pop(context);
#         if (pModel != null) {
#             Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
#         } else {
#             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب غير موجود')));
#         }
#     });
#     },
#                 child: Container(
#                   padding: const EdgeInsets.all(12),
#                   ...

import re
c = re.sub(r'context\.read<PlayerRepository>\(\)\.getPlayerById\(player\.id\)', r'context.read<PlayerRepository>().getPlayerById(player.playerId)', c)

# Let's check for the missing parenthesis. The python script earlier did:
# old_roster_container = r"return Container\(\s*padding: const EdgeInsets.all\(12\),"
# new_roster_container = """return GestureDetector(
#                 onTap: () { ... },
#                 child: Container(
#                   padding: const EdgeInsets.all(12),"""
# 
# Wait! I just added a `return GestureDetector(..., child: Container(...)` but I didn't add the `);` at the end of the `GestureDetector`! That's why it complains about missing `)`.
# Let's fix this properly. 
# The original code ended the `Container(` at the end of the item builder!
# It returned `Container( ... );`
# So I should find `);` at the end of that widget and replace it with `), );` or similar.
pass
