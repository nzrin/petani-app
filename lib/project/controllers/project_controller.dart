import 'package:flutter/foundation.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/repositories/project_repository.dart';

class ProjectController extends ChangeNotifier {
  ProjectController(this._repository);

  final ProjectRepository _repository;

  List<ProjectRecord> projects = const [];
  bool isLoading = false;
  bool hasLoadError = false;
  final Set<String> deletingProjectKeys = {};
  int _loadRequest = 0;

  bool isDeleting(ProjectRecord project) {
    return deletingProjectKeys.contains(project.key);
  }

  Future<ProjectFormSuggestions> getFormSuggestions() {
    return _repository.getFormSuggestions();
  }

  Future<ProjectRecord?> createPlot(ProjectFormData data) async {
    await _repository.createProject(data);
    await loadProjects();
    return _findProject(data.projectName);
  }

  Future<ProjectRecord?> updatePlot({
    required int plotId,
    required ProjectFormData data,
  }) async {
    await _repository.updatePlot(plotId: plotId, data: data);
    await loadProjects();
    return _findProject(data.projectName);
  }

  Future<ProjectRecord?> updateProject({
    required ProjectRecord project,
    required String projectName,
    required String location,
  }) async {
    await _repository.updateProject(
      currentProjectName: project.projectName,
      projectName: projectName,
      location: location,
    );
    await loadProjects();
    return _findProject(projectName);
  }

  Future<ProjectRecord?> deletePlot({
    required ProjectRecord project,
    required int plotId,
  }) async {
    await _repository.deletePlot(plotId);
    await loadProjects();
    return _findProject(project.projectName);
  }

  ProjectRecord? _findProject(String projectName) {
    final normalizedName = _normalizeName(projectName);
    for (final project in projects) {
      if (_normalizeName(project.projectName) == normalizedName) {
        return project;
      }
    }
    return null;
  }

  Future<bool> deleteProject(ProjectRecord project) async {
    if (isDeleting(project)) return false;
    deletingProjectKeys.add(project.key);
    notifyListeners();

    try {
      await _repository.deleteProject(project.projectName);
      await loadProjects();
      return true;
    } catch (_) {
      return false;
    } finally {
      deletingProjectKeys.remove(project.key);
      notifyListeners();
    }
  }

  Future<void> loadProjects() async {
    final request = ++_loadRequest;

    isLoading = true;
    hasLoadError = false;
    notifyListeners();

    try {
      final loadedProjects = await _repository.getProjects();
      if (request == _loadRequest) {
        projects = loadedProjects;
      }
    } catch (_) {
      if (request == _loadRequest) {
        hasLoadError = true;
      }
    } finally {
      if (request == _loadRequest) {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}

String _normalizeName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
