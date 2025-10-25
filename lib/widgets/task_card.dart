import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildLeading(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading() {
    return Stack(
      children: [
        // Círculo da categoria
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: task.category.color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: task.category.color,
              width: 2,
            ),
          ),
          child: Icon(
            _getPriorityIcon(),
            color: task.category.color,
            size: 20,
          ),
        ),
        // Indicador de vencimento
        if (task.isOverdue)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: task.completed ? TextDecoration.lineThrough : null,
              color: task.completed ? Colors.grey : null,
            ),
          ),
        ),
        // Badge de categoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: task.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.category.name,
            style: TextStyle(
              fontSize: 10,
              color: task.category.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.description.isNotEmpty)
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        if (task.dueDate != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: task.isOverdue ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'Vence: ${_formatDueDate(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: task.isOverdue ? Colors.red : Colors.grey,
                  fontWeight: task.isOverdue ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'toggle') onToggle();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                task.completed ? Icons.undo : Icons.check,
                color: task.completed ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(task.completed ? 'Marcar Pendente' : 'Concluir'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Excluir'),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent':
        return Icons.outlined_flag;
      case 'high':
        return Icons.flag;
      case 'medium':
        return Icons.outlined_flag;
      case 'low':
        return Icons.flag_outlined;
      default:
        return Icons.flag;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final due = DateTime(date.year, date.month, date.day);

    if (due == today) return 'Hoje';
    if (due == tomorrow) return 'Amanhã';
    
    final difference = due.difference(today).inDays;
    if (difference < 0) {
      return 'Há ${difference.abs()} dias';
    } else if (difference <= 7) {
      return 'Em $difference dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}