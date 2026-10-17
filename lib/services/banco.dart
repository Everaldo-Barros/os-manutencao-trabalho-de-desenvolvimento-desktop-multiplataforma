import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Banco {
  Banco._();
  static final Banco instance = Banco._();
  Database? _db;
  Future<Database> get db async {
    if (_db != null) return _db!;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _db = await openDatabase(p.join(dir.path, 'manutencao.db'),
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE clientes (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, documento TEXT NOT NULL, telefone TEXT NOT NULL, email TEXT NOT NULL, endereco TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE tecnicos (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, contato TEXT NOT NULL, especialidade TEXT NOT NULL, situacao TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE equipamentos (id INTEGER PRIMARY KEY AUTOINCREMENT, cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT, tipo TEXT NOT NULL, marca TEXT NOT NULL, modelo TEXT NOT NULL, serie TEXT NOT NULL, patrimonio TEXT NOT NULL, observacoes TEXT NOT NULL)');
          await db.execute(
              "CREATE TABLE ordens (id INTEGER PRIMARY KEY AUTOINCREMENT, cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT, equipamento_id INTEGER NOT NULL REFERENCES equipamentos(id) ON DELETE RESTRICT, tecnico_id INTEGER REFERENCES tecnicos(id) ON DELETE RESTRICT, problema TEXT NOT NULL, diagnostico TEXT NOT NULL DEFAULT '', solucao TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Aberta', prioridade TEXT NOT NULL DEFAULT 'Média', prazo TEXT NOT NULL DEFAULT '', imagem TEXT NOT NULL DEFAULT '', mao_obra REAL NOT NULL DEFAULT 0, pecas REAL NOT NULL DEFAULT 0)");
          await db.execute(
              'CREATE TABLE historico (id INTEGER PRIMARY KEY AUTOINCREMENT, ordem_id INTEGER NOT NULL REFERENCES ordens(id) ON DELETE CASCADE, status TEXT NOT NULL, data TEXT NOT NULL)');
        });
    return _db!;
  }

  Future<List<Map<String, Object?>>> listar(String tabela) async =>
      (await db).query(tabela, orderBy: 'id DESC');
  Future<int> salvar(String tabela, Map<String, Object?> valores) async {
    final banco = await db;
    final dados = Map<String, Object?>.from(valores);
    final id = dados.remove('id') as int?;
    if (id == null) return banco.insert(tabela, dados);
    await banco.update(tabela, dados, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> excluir(String tabela, int id) async =>
      (await db).delete(tabela, where: 'id = ?', whereArgs: [id]);
  Future<void> registrarStatus(int id, String status) async =>
      (await db).insert('historico', {
        'ordem_id': id,
        'status': status,
        'data': DateTime.now().toIso8601String()
      });
  Future<List<Map<String, Object?>>> historico(int id) async =>
      (await db).query('historico',
          where: 'ordem_id = ?', whereArgs: [id], orderBy: 'id DESC');
}
