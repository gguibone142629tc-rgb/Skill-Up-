import 'package:flutter/material.dart';
import '../models/session_model.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  const SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(builder: (context) {
                final initials = session.name.trim().isNotEmpty
                    ? session.name.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
                    : '';

                if (session.imagePath.isNotEmpty && (session.imagePath.startsWith('http') || session.imagePath.startsWith('https'))) {
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    backgroundImage: NetworkImage(session.imagePath),
                    onBackgroundImageError: (_, __) {},
                  );
                } else {
                  // Try project default asset first, otherwise show initials
                  return FutureBuilder<bool>(
                    future: Future<bool>.delayed(Duration.zero, () => true), // quick microtask to allow errorBuilder handling
                    builder: (context, snap) {
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: Image.asset(
                            'images/default_avatar.png',
                            height: 48,
                            width: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Text(initials, style: const TextStyle(color: Color(0xFF2D6A65), fontWeight: FontWeight.bold)));
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    Text(session.role, 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ],
                ),
              ),
              _buildStatusBadge(session.status),
            ],
          ),
          const SizedBox(height: 16),
          // Date/Time Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(session.date),
                const SizedBox(width: 12),
                Container(height: 14, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(session.time),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(session.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    Color color;
    String text;
    switch (status) {
      case SessionStatus.upcoming:
        color = const Color(0xFF3B7A77);
        text = "Upcoming";
        break;
      case SessionStatus.completed:
        color = Colors.grey.shade200;
        text = "Completed";
        break;
      case SessionStatus.cancelled:
        color = const Color(0xFFFF6B57);
        text = "Cancelled";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: status == SessionStatus.completed ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(SessionStatus status) {
    if (status == SessionStatus.upcoming) {
      return Row(
        children: [
          Expanded(child: _button("Message", true)),
          const SizedBox(width: 12),
          Expanded(child: _button("Reschedule", true)),
        ],
      );
    } else if (status == SessionStatus.completed) {
      return _button("Book Again", false);
    } else {
      return _button("Cancelled", false, isDisabled: true);
    }
  }

  Widget _button(String label, bool isPrimary, {bool isDisabled = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade50 : (isPrimary ? const Color(0xFF3B7A77) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: !isPrimary && !isDisabled ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Center(
        child: Text(label, style: TextStyle(
          color: isDisabled ? Colors.grey.shade400 : (isPrimary ? Colors.white : Colors.black87),
          fontWeight: FontWeight.bold,
        )),
      ),
    );
  }
}