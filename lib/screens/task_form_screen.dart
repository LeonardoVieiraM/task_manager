import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _priority = 'medium';
  bool _completed = false;
  bool _isLoading = false;
  DateTime? _dueDate;
  Category? _selectedCategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Inicializar controllers com dados da tarefa (se houver)
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _completed = widget.task!.completed;
      _dueDate = widget.task!.dueDate;
      // _selectedCategory será definido após carregar as categorias
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getAllCategories();
      
      setState(() {
        _categories = categories;
        
        // Se estiver editando uma tarefa, encontrar a categoria correspondente
        if (widget.task != null && categories.isNotEmpty) {
          // Encontrar a categoria que corresponde à categoria da tarefa pelo ID
          final taskCategoryId = widget.task!.category.id;
          _selectedCategory = categories.firstWhere(
            (category) => category.id == taskCategoryId,
            orElse: () => categories.last, // Fallback para a última categoria
          );
        } else if (_selectedCategory == null && categories.isNotEmpty) {
          _selectedCategory = categories.last;
        }
      });
      
      print('Categorias carregadas: ${_categories.length}');
      print('Categoria selecionada: ${_selectedCategory?.name}');
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }
  }

  Future<void> _selectDueDate() async {
    final initialDate = _dueDate ?? DateTime.now();
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _dueDate = pickedDate);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma categoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.task == null) {
        // Criar nova tarefa
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          dueDate: _dueDate,
          category: _selectedCategory!,
        );
        await DatabaseService.instance.create(newTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Tarefa criada com sucesso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Atualizar tarefa existente
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          dueDate: _dueDate,
          category: _selectedCategory,
        );
        await DatabaseService.instance.update(updatedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Tarefa atualizada com sucesso'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Ex: Estudar Flutter',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, digite um título';
                        }
                        if (value.trim().length < 3) {
                          return 'Título deve ter pelo menos 3 caracteres';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campo de Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Adicione mais detalhes...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      maxLength: 500,
                    ),
                    
                    const SizedBox(height: 16),

                    // Dropdown de Categoria - CORRIGIDO
                    _categories.isEmpty
                        ? const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Carregando categorias...'),
                          )
                        : DropdownButtonFormField<Category>(
                            decoration: const InputDecoration(
                              labelText: 'Categoria *',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategory,
                            items: _categories.map((Category category) {
                              return DropdownMenuItem<Category>(
                                value: category,
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
                                    const SizedBox(width: 12),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            validator: (Category? value) {
                              if (value == null) {
                                return 'Por favor, selecione uma categoria';
                              }
                              return null;
                            },
                          ),
                    
                    const SizedBox(height: 16),
                    
                    // Campo de Data de Vencimento
                    InkWell(
                      onTap: _selectDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de Vencimento',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dueDate == null
                                  ? 'Selecionar data'
                                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                              style: TextStyle(
                                color: _dueDate == null
                                    ? Colors.grey.shade600
                                    : null,
                              ),
                            ),
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => _dueDate = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dropdown de Prioridade
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Baixa'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Média'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Alta'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Urgente'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Switch de Completo
                    Card(
                      child: SwitchListTile(
                        title: const Text('Tarefa Completa'),
                        subtitle: Text(
                          _completed 
                              ? 'Esta tarefa está marcada como concluída'
                              : 'Esta tarefa ainda não foi concluída',
                        ),
                        value: _completed,
                        onChanged: (value) {
                          setState(() => _completed = value);
                        },
                        secondary: Icon(
                          _completed ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _completed ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão Salvar
                    ElevatedButton.icon(
                      onPressed: _saveTask,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Atualizar Tarefa' : 'Criar Tarefa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Botão Cancelar
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}