import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Versão incrementada
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela de categorias
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Tabela de tarefas
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        categoryId TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Inserir categorias padrão
    await _insertDefaultCategories(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar tabela de categorias
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER NOT NULL
        )
      ''');

      // Inserir categorias padrão
      await _insertDefaultCategories(db);

      // Adicionar novas colunas na tabela tasks
      await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN categoryId TEXT');

      // Atualizar tarefas existentes para usar categoria "Outros"
      final othersCategory = defaultCategories.last;
      await db.update(
        'tasks',
        {'categoryId': othersCategory.id},
      );

      // Adicionar chave estrangeira
      await db.execute('''
        CREATE TABLE tasks_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          completed INTEGER NOT NULL,
          priority TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          dueDate TEXT,
          categoryId TEXT NOT NULL,
          FOREIGN KEY (categoryId) REFERENCES categories (id)
        )
      ''');

      await db.execute('''
        INSERT INTO tasks_new 
        SELECT id, title, description, completed, priority, createdAt, dueDate, categoryId 
        FROM tasks
      ''');

      await db.execute('DROP TABLE tasks');
      await db.execute('ALTER TABLE tasks_new RENAME TO tasks');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // Métodos para Categorias
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategory(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final categories = await getAllCategories();
      return Task.fromMap(maps.first, categories);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    final categories = await getAllCategories();
    return result.map((map) => Task.fromMap(map, categories)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}