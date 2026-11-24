import '../backend_client.dart';
import '../pictograms/catalog_api.dart';

const maxRoutineSteps = 12;

class RoutineStep {
  RoutineStep({
    this.label = '',
    this.searchTerm = '',
    this.association = '',
    this.pictogram,
    this.approved = false,
    this.candidates = const [],
  });

  factory RoutineStep.fromJson(
    Map<String, dynamic> json, {
    required bool saved,
  }) {
    final picture = json[saved ? 'pictogram' : 'selected'];
    return RoutineStep(
      label: json['label'] as String,
      searchTerm: (json['search_term'] as String?) ?? '',
      association: (json['association'] as String?) ?? '',
      pictogram: picture == null
          ? null
          : Pictogram.fromJson(picture as Map<String, dynamic>),
      approved: saved,
      candidates: (json['candidates'] as List? ?? [])
          .map((value) => Pictogram.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }

  String label;
  final String searchTerm;
  final String association;
  Pictogram? pictogram;
  bool approved;
  final List<Pictogram> candidates;

  RoutineStep copy() => RoutineStep(
    label: label,
    searchTerm: searchTerm,
    association: association,
    pictogram: pictogram,
    approved: approved,
    candidates: candidates,
  );

  Map<String, Object?> toJson(int order) {
    final picture = pictogram;
    return {
      'order': order,
      'label': label.trim(),
      'approved': approved,
      if (picture?.id != null)
        'pictogram_id': picture!.id
      else if (picture != null) ...{
        'external_id': picture.externalId,
        'pictogram_label': picture.label,
      },
    };
  }
}

class RoutineData {
  const RoutineData({
    this.id,
    this.name = '',
    this.description = '',
    this.steps = const [],
  });

  factory RoutineData.fromJson(Map<String, dynamic> response) {
    final id = response['id'] as int?;
    final rows = (response['steps'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['order'] != i + 1) {
        throw const FormatException('La rutina contiene pasos fuera de orden.');
      }
    }
    return RoutineData(
      id: id,
      name: response['name'] as String,
      description: response['description'] as String,
      steps: rows
          .map((step) => RoutineStep.fromJson(step, saved: id != null))
          .toList(),
    );
  }

  final int? id;
  final String name;
  final String description;
  final List<RoutineStep> steps;

  Map<String, dynamic> approval() => {
    'name': name.trim(),
    'description': description.trim(),
    'confirmed': true,
    'steps': [for (var i = 0; i < steps.length; i++) steps[i].toJson(i + 1)],
  };
}

abstract interface class RoutineStore {
  Future<List<RoutineData>> list();
  Future<RoutineData> get(int id);
  Future<RoutineData> generate(String description);
  Future<RoutineData> save(RoutineData routine);
  Future<void> delete(int id);
}

class RoutineApi implements RoutineStore {
  RoutineApi([BackendClient? client]) : _client = client ?? BackendClient();
  final BackendClient _client;
  static const _path = '/api/v1/routines';

  @override
  Future<List<RoutineData>> list() async =>
      (await _client.requestJson('GET', _path) as List)
          .map((row) => RoutineData.fromJson(row as Map<String, dynamic>))
          .toList();

  @override
  Future<RoutineData> get(int id) async => RoutineData.fromJson(
    await _client.requestJson('GET', '$_path/$id') as Map<String, dynamic>,
  );

  @override
  Future<RoutineData> generate(String description) async =>
      RoutineData.fromJson(
        await _client.requestJson(
          'POST',
          '$_path/proposals',
          responseTimeout: const Duration(seconds: 160),
          body: {'description': description},
        ) as Map<String, dynamic>,
      );

  @override
  Future<RoutineData> save(RoutineData routine) async {
    final id = routine.id;
    return RoutineData.fromJson(
      await _client.requestJson(
        id == null ? 'POST' : 'PUT',
        id == null ? _path : '$_path/$id',
        body: routine.approval(),
        responseTimeout: const Duration(seconds: 75),
      ) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> delete(int id) async {
    await _client.requestJson('DELETE', '$_path/$id');
  }
}
