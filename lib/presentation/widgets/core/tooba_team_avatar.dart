import 'package:flutter/material.dart';

class ToobaTeamAvatar extends StatelessWidget {
  final String logoUrl;
  final double radius;
  final bool isElite;

  const ToobaTeamAvatar({
    super.key,
    required this.logoUrl,
    this.radius = 24.0,
    this.isElite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isElite ? 2.0 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isElite 
            ? const LinearGradient(colors: [Color(0xFF1877F2), Color(0xFF4294FF)]) 
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
        child: logoUrl.isEmpty 
            ? Icon(Icons.shield, size: radius * 1.2, color: Colors.grey.shade500) 
            : null,
      ),
    );
  }
}
