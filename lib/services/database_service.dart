// lib/services/database_service.dart - VERSÃO FINAL CORRIGIDA
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/problem.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _problemsCollection = 'problems';

  // ✅ CRIAR NOVO PROBLEMA
  static Future<String> createProblem(Problem problem) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_problemsCollection).add(problem.toMap());

      print('✅ Problema criado com sucesso! ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar problema: $e');
      throw Exception('Erro ao salvar problema: $e');
    }
  }

  // ✅ BUSCAR TODOS OS PROBLEMAS (Stream em tempo real)
  static Stream<List<Problem>> getAllProblemsStream() {
    return _firestore
        .collection(_problemsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Problem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ✅ BUSCAR PROBLEMAS ATIVOS (não resolvidos)
  static Stream<List<Problem>> getActiveProblemsStream() {
    return _firestore
        .collection(_problemsCollection)
        .where('status', whereIn: ['pending', 'in_progress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Problem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // ✅ BUSCAR POR STATUS
  static Stream<List<Problem>> getProblemsByStatus(ProblemStatus status) {
    return _firestore
        .collection(_problemsCollection)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Problem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ✅ CURTIR PROBLEMA (incrementar likes)
  static Future<void> likeProblem(String problemId) async {
    try {
      await _firestore.collection(_problemsCollection).doc(problemId).update({
        'likes': FieldValue.increment(1),
      });

      print('✅ Like adicionado ao problema: $problemId');
    } catch (e) {
      print('❌ Erro ao curtir problema: $e');
      throw Exception('Erro ao curtir problema');
    }
  }

  // ✅ ATUALIZAR STATUS DO PROBLEMA
  static Future<void> updateProblemStatus(
      String problemId, ProblemStatus newStatus) async {
    try {
      await _firestore.collection(_problemsCollection).doc(problemId).update({
        'status': newStatus.toString().split('.').last,
      });

      print('✅ Status atualizado: $problemId -> $newStatus');
    } catch (e) {
      print('❌ Erro ao atualizar status: $e');
      throw Exception('Erro ao atualizar problema');
    }
  }

  // ✅ DELETAR PROBLEMA
  static Future<void> deleteProblem(String problemId) async {
    try {
      await _firestore.collection(_problemsCollection).doc(problemId).delete();

      print('✅ Problema deletado: $problemId');
    } catch (e) {
      print('❌ Erro ao deletar problema: $e');
      throw Exception('Erro ao deletar problema');
    }
  }

  // ✅ ESTATÍSTICAS DO DASHBOARD
  static Future<Map<String, int>> getDashboardStats() async {
    try {
      QuerySnapshot allProblems =
          await _firestore.collection(_problemsCollection).get();

      int total = allProblems.docs.length;
      int active = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var doc in allProblems.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];

        if (status == 'pending')
          active++;
        else if (status == 'in_progress')
          inProgress++;
        else if (status == 'resolved') resolved++;
      }

      return {
        'total': total,
        'active': active,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'active': 0,
        'inProgress': 0,
        'resolved': 0,
      };
    }
  }
}
