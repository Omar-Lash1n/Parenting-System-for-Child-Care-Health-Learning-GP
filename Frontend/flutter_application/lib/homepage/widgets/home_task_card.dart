import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Ajial/homepage/models/upcoming_task_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class HomeTaskCard extends StatelessWidget {
  final UpcomingTaskModel task;

  const HomeTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final hasAssignee = task.assignees.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: task.color, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2.5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: _kPrimary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Opacity(
                opacity: 0.5,
                child: Icon(Icons.more_horiz_rounded, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _formatDate(task.dueDate),
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Opacity(
                    opacity: 0.5,
                    child: Icon(Icons.calendar_today_outlined, size: 16),
                  ),
                ],
              ),
              if (hasAssignee)
                _AssigneeAvatar(assignee: task.assignees.first)
              else
                const SizedBox(width: 34),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final HomeTaskAssigneeModel assignee;

  const _AssigneeAvatar({required this.assignee});

  @override
  Widget build(BuildContext context) {
    final initial = assignee.name.isNotEmpty ? assignee.name.substring(0, 1) : 'ط';
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0x26FE8401),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: assignee.imageUrl != null && assignee.imageUrl!.isNotEmpty
          ? Image.network(
              assignee.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initial(initial: initial),
            )
          : _Initial(initial: initial),
    );
  }
}

class _Initial extends StatelessWidget {
  final String initial;

  const _Initial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}
