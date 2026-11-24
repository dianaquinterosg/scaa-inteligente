import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../backend_client.dart';

const maxImageBytes = 5 * 1024 * 1024;

class Category {
  const Category(this.id, this.name);
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(json['id'] as int, json['name'] as String);
  final int id;
  final String name;
}

class Pictogram {
  const Pictogram({
    this.id,
    this.externalId,
    required this.label,
    required this.imagePath,
    this.categoryIds = const [],
    this.attribution,
  });

  factory Pictogram.fromJson(Map<String, dynamic> json) => Pictogram(
    id: json['id'] as int?,
    externalId: json['external_id'] as int?,
    label: json['label'] as String,
    imagePath: json['image_url'] as String,
    categoryIds: (json['category_ids'] as List?)?.cast<int>() ?? const [],
    attribution: json['attribution'] as String?,
  );

  final int? id;
  final int? externalId;
  final String label;
  final String imagePath;
  final List<int> categoryIds;
  final String? attribution;
}

class CatalogSearch {
  const CatalogSearch(this.local, this.remote, this.remoteStatus);
  final List<Pictogram> local;
  final List<Pictogram> remote;
  final String remoteStatus;
}

class PictogramInUse implements Exception {
  const PictogramInUse(this.message, this.routines);

  final String message;
  final List<({int id, String name})> routines;
}

abstract interface class CatalogStore {
  Future<List<Category>> categories();
  Future<List<Pictogram>> list({int? categoryId});
  Future<CatalogSearch> search(
    String query, {
    int? categoryId,
    bool alternatives = false,
  });
  Uri imageUrl(Pictogram item);
  Future<Uint8List> preview(Pictogram item);
  Future<void> save(
    String label,
    List<int> categories, {
    Pictogram? item,
    Uint8List? image,
  });
  Future<void> delete(int id);
  Future<void> saveCategory(String name, {int? id});
  Future<void> deleteCategory(int id);
}

class CatalogApi implements CatalogStore {
  CatalogApi([BackendClient? client]) : _client = client ?? BackendClient();
  final BackendClient _client;
  static const _catalog = '/api/v1/pictograms';
  static const _categories = '/api/v1/categories';

  String _path(String path, Map<String, String> params) => Uri(
    path: path,
    queryParameters: params.isEmpty ? null : params,
  ).toString();

  List<Pictogram> _items(Object? json) => (json as List)
      .map((item) => Pictogram.fromJson(item as Map<String, dynamic>))
      .toList();

  @override
  Future<List<Category>> categories() async =>
      (await _client.requestJson('GET', _categories) as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();

  @override
  Future<List<Pictogram>> list({int? categoryId}) async => _items(
    await _client.requestJson(
      'GET',
      _path(_catalog, {if (categoryId != null) 'category_id': '$categoryId'}),
    ),
  );

  @override
  Future<CatalogSearch> search(
    String query, {
    int? categoryId,
    bool alternatives = false,
  }) async {
    final data = await _client.requestJson(
      'GET',
      _path('$_catalog/search', {
        'q': query,
        if (categoryId != null) 'category_id': '$categoryId',
        if (alternatives) 'alternatives': 'true',
      }),
    ) as Map<String, dynamic>;
    return CatalogSearch(
      _items(data['local']),
      _items(data['alternatives']),
      data['remote_status'] as String,
    );
  }

  @override
  Uri imageUrl(Pictogram item) => _client.baseUri.resolve(item.imagePath);

  @override
  Future<Uint8List> preview(Pictogram item) async {
    const timeout = Duration(seconds: 6);
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(imageUrl(item)).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          'No pudimos abrir esta imagen.',
        );
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > maxImageBytes) {
          throw const ApiException(413, 'La imagen supera el máximo de 5 MB.');
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> save(
    String label,
    List<int> categories, {
    Pictogram? item,
    Uint8List? image,
  }) async {
    final id = item?.id;
    await _client.requestJson(
      id == null ? 'POST' : 'PUT',
      id == null ? _catalog : '$_catalog/$id',
      body: {
        'label': label,
        'category_ids': categories,
        if (id == null) ...{
          'confirmed': true,
          if (image != null)
            'image_base64': base64Encode(image)
          else
            'external_id': item?.externalId,
        },
      },
    );
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _client.requestJson('DELETE', '$_catalog/$id');
    } on ApiException catch (error) {
      final detail = error.detail;
      final routines = detail?['routines'];
      if (error.statusCode == 409 &&
          detail?['code'] == 'pictogram_in_use' &&
          routines is List) {
        throw PictogramInUse(error.message, [
          for (final routine in routines)
            if (routine case {'id': final int id, 'name': final String name})
              (id: id, name: name),
        ]);
      }
      rethrow;
    }
  }

  @override
  Future<void> saveCategory(String name, {int? id}) async {
    await _client.requestJson(
      id == null ? 'POST' : 'PUT',
      id == null ? _categories : '$_categories/$id',
      body: {'name': name},
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _client.requestJson('DELETE', '$_categories/$id');
  }
}
