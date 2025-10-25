import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  String _filter = 'all'; // all, completed, pending
  String _sortBy = 'date'; // date, priority, title, dueDate
  String? _categoryFilter; // null = todas as categorias
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tasksFuture = DatabaseService.instance.readAll();
      final categoriesFuture = DatabaseService.instance.getAllCategories();
      
      final results = await Future.wait([tasksFuture, categoriesFuture]);
      
      setState(() {
        _tasks = results[0] as List<Task>; // Cast explícito
        _categories = results[1] as List<Category>; // Cast explícito
        _isLoading = false;
      });

      // Mostrar alerta para tarefas vencidas
      _showOverdueTasksAlert();
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro ao carregar dados: $e');
    }
  }

  void _showOverdueTasksAlert() {
    final overdueTasks = _tasks.where((t) => t.isOverdue).toList();
    if (overdueTasks.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Tarefas Vencidas'),
              ],
            ),
            content: Text(
              'Você tem ${overdueTasks.length} tarefa(s) vencida(s).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  List<Task> get _filteredTasks {
    var tasks = _tasks;

    // Filtro por status
    switch (_filter) {
      case 'completed':
        tasks = tasks.where((t) => t.completed).toList();
        break;
      case 'pending':
        tasks = tasks.where((t) => !t.completed).toList();
        break;
    }

    // Filtro por categoria
    if (_categoryFilter != null) {
      tasks = tasks.where((t) => t.category.id == _categoryFilter).toList();
    }

    // Ordenação
    switch (_sortBy) {
      case 'priority':
        final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
        tasks.sort((a, b) {
          final orderA = priorityOrder[a.priority] ?? 2;
          final orderB = priorityOrder[b.priority] ?? 2;
          return orderA.compareTo(orderB);
        });
        break;
      case 'title':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'dueDate':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'date':
      default:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return tasks;
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _loadData();
  }

  Future<void> _deleteTask(Task task) async {
    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete(task.id);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa excluída'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final stats = _calculateStats();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Menu de Filtro por Categoria
          PopupMenuButton<String?>(
            icon: const Icon(Icons.category),
            onSelected: (value) => setState(() => _categoryFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('Todas as Categorias'),
                  ],
                ),
              ),
              ..._categories.map((category) => PopupMenuItem(
                value: category.id,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              )).toList(),
            ],
          ),
          
          // Menu de Ordenação
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Ordenar por Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Ordenar por Prioridade'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.title),
                    SizedBox(width: 8),
                    Text('Ordenar por Título'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Ordenar por Vencimento'),
                  ],
                ),
              ),
            ],
          ),

          // Menu de Filtro por Status
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    Text('Pendentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Concluídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      body: Column(
        children: [
          // Indicadores de Filtro Ativo
          if (_categoryFilter != null || _filter != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_categoryFilter != null)
                          Chip(
                            label: Text(
                              _categories
                                  .firstWhere((c) => c.id == _categoryFilter)
                                  .name,
                            ),
                            backgroundColor: _categories
                                .firstWhere((c) => c.id == _categoryFilter)
                                .color
                                .withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _categories
                                  .firstWhere((c) => c.id == _categoryFilter)
                                  .color,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _categoryFilter = null),
                          ),
                        if (_filter != 'all')
                          Chip(
                            label: Text(
                              _filter == 'completed' ? 'Concluídas' : 'Pendentes',
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _filter = 'all'),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _categoryFilter = null;
                      _filter = 'all';
                    }),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
          
          // Card de Estatísticas
          if (_tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.list,
                    'Total',
                    stats['total'].toString(),
                  ),
                  _buildStatItem(
                    Icons.pending_actions,
                    'Pendentes',
                    stats['pending'].toString(),
                  ),
                  _buildStatItem(
                    Icons.check_circle,
                    'Concluídas',
                    stats['completed'].toString(),
                  ),
                  _buildStatItem(
                    Icons.warning,
                    'Vencidas',
                    stats['overdue'].toString(),
                    textColor: stats['overdue']! > 0 ? Colors.orange : Colors.white, // Corrigido
                  ),
                ],
              ),
            ),
          
          // Lista de Tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => _openTaskForm(task),
                              onToggle: () => _toggleTask(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? textColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor ?? Colors.white, // Usando textColor em vez de color
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_filter) {
      case 'completed':
        message = 'Nenhuma tarefa concluída ainda';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        message = 'Nenhuma tarefa pendente';
        icon = Icons.pending_actions;
        break;
      default:
        message = 'Nenhuma tarefa cadastrada';
        icon = Icons.task_alt;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openTaskForm(),
            icon: const Icon(Icons.add),
            label: const Text('Criar primeira tarefa'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.completed).length,
      'pending': _tasks.where((t) => !t.completed).length,
      'overdue': _tasks.where((t) => t.isOverdue).length,
    };
  }
}