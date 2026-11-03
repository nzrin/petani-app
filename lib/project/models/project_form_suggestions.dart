class ProjectFormSuggestions {
  const ProjectFormSuggestions({
    this.existingProjects = const [],
    this.locations = const [],
  });

  final List<ExistingProjectSuggestion> existingProjects;
  final List<String> locations;
}

class ExistingProjectSuggestion {
  const ExistingProjectSuggestion({
    required this.name,
    required this.location,
    this.plotNames = const [],
  });

  final String name;
  final String location;
  final List<String> plotNames;
}
