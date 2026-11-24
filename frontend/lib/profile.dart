import 'backend_client.dart';

enum ContextKind {
  interest('interests', 'Intereses', 'interés'),
  activity('activities', 'Actividades', 'actividad'),
  routine('frequent_routines', 'Rutinas frecuentes', 'rutina frecuente');

  const ContextKind(this.field, this.title, this.itemLabel);
  final String field;
  final String title;
  final String itemLabel;
}

class ProfileData {
  ProfileData({
    required this.alias,
    List<String> interests = const [],
    List<String> activities = const [],
    List<String> frequentRoutines = const [],
  }) : interests = List.unmodifiable(interests),
       activities = List.unmodifiable(activities),
       frequentRoutines = List.unmodifiable(frequentRoutines);

  final String alias;
  final List<String> interests;
  final List<String> activities;
  final List<String> frequentRoutines;

  List<String> values(ContextKind kind) => switch (kind) {
    ContextKind.interest => interests,
    ContextKind.activity => activities,
    ContextKind.routine => frequentRoutines,
  };

  Map<String, dynamic> toJson() => {
    'alias': alias.trim(),
    for (final kind in ContextKind.values)
      kind.field: values(kind).map((value) => value.trim()).toList(),
  };

  factory ProfileData.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] != 1 ||
        value['alias'] is! String) {
      throw const FormatException('Respuesta de perfil no válida');
    }
    List<String> items(String field) {
      final data = value[field];
      if (data is! List || data.any((item) => item is! String)) {
        throw const FormatException('Contexto de perfil no válido');
      }
      return data.cast<String>();
    }

    return ProfileData(
      alias: value['alias'] as String,
      interests: items('interests'),
      activities: items('activities'),
      frequentRoutines: items('frequent_routines'),
    );
  }
}

abstract interface class ProfileStore {
  Future<ProfileData?> load();
  Future<ProfileData> save(ProfileData draft);
}

class ProfileApi implements ProfileStore {
  ProfileApi({BackendClient? client}) : _client = client ?? BackendClient();
  final BackendClient _client;

  @override
  Future<ProfileData?> load() async {
    try {
      return ProfileData.fromJson(
        await _client.requestJson('GET', '/api/v1/profile'),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404 && error.message == 'Perfil no configurado') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ProfileData> save(ProfileData draft) async => ProfileData.fromJson(
    await _client.requestJson('PUT', '/api/v1/profile', body: draft.toJson()),
  );
}
