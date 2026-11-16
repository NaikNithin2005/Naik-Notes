import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naik_notes/core/config/app_config.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/template_store_model.dart';
import 'package:naik_notes/data/repositories/template_store_repository.dart';

/// Service coordinating community template downloads, custom template creation,
/// JSON export/import, and local template library persistence.
class TemplateStoreService {
  final TemplateStoreRepository repository;
  final http.Client _client;
  final String _baseUrl;

  TemplateStoreService({
    required this.repository,
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.devApiBaseUrl;

  /// Fetches community template catalog with optional category and search query filters.
  Future<List<CustomTemplate>> fetchCommunityCatalog({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$_baseUrl/templates',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final templatesJson = data['templates'] as List<dynamic>;
        return templatesJson
            .map((e) => CustomTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Community catalog API fallback: $e');
    }

    // Offline / Fallback Seed Catalog
    return _getFallbackCatalog(category: category, search: search);
  }

  /// Installs a template into the local notebook templates library.
  Future<void> installTemplate(CustomTemplate template) async {
    final installed = template.copyWith(
      isInstalled: true,
      updatedAt: DateTime.now(),
    );
    await repository.saveCustomTemplate(installed);

    // Notify backend of download asynchronously
    try {
      final uri = Uri.parse('$_baseUrl/templates/${template.id}/download');
      _client.post(uri).ignore();
    } catch (_) {}
  }

  /// Uninstalls / hides a template from the user's active templates picker.
  Future<void> uninstallTemplate(String templateId) async {
    await repository.setTemplateInstalled(templateId, false);
  }

  /// Saves a user-created paper customizer preset as a new reusable template.
  Future<CustomTemplate> createCustomTemplate({
    required String title,
    required String description,
    required String category,
    required PaperProperties properties,
    String author = 'Me',
  }) async {
    final template = CustomTemplate(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      author: author,
      properties: properties,
      isInstalled: true,
      isBuiltIn: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.saveCustomTemplate(template);
    return template;
  }

  /// Publishes a custom template to the online community marketplace.
  Future<CustomTemplate?> publishToCommunity(CustomTemplate template) async {
    try {
      final uri = Uri.parse('$_baseUrl/templates');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(template.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final published = CustomTemplate.fromJson(data);
        await repository.saveCustomTemplate(published);
        return published;
      }
    } catch (e) {
      debugPrint('Publish template failed: $e');
    }
    return null;
  }

  /// Exports template definition to a shareable JSON string.
  String exportTemplateToJson(CustomTemplate template) {
    return const JsonEncoder.withIndent('  ').convert(template.toJson());
  }

  /// Imports and validates a template from a JSON string.
  Future<CustomTemplate?> importTemplateFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final template = CustomTemplate.fromJson(data).copyWith(
        id: 'imported-${DateTime.now().millisecondsSinceEpoch}',
        isInstalled: true,
      );
      await repository.saveCustomTemplate(template);
      return template;
    } catch (e) {
      debugPrint('Failed to import template JSON: $e');
      return null;
    }
  }

  List<CustomTemplate> _getFallbackCatalog({String? category, String? search}) {
    final list = [
      CustomTemplate(
        id: 'tpl-dark-engineering-grid',
        title: 'Dark Mode Precision Quad Grid',
        description:
            '5mm quad grid with dark slate paper tone, cyan guide lines, and technical header block for engineering calculations.',
        category: 'Engineering',
        author: 'Prof. Naik',
        properties: const PaperProperties(
          backgroundColorHex: '#1E2022',
          lineColorHex: '#334155',
          accentColorHex: '#06B6D4',
          gridSize: 14.17,
          lineSpacing: 20.0,
          marginTop: 56.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          hasHeaderArea: true,
          headerHeight: 44.0,
          pageSize: 'A4',
          orientation: 'portrait',
          showPageNumber: true,
        ),
        downloadCount: 342,
        rating: 4.9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CustomTemplate(
        id: 'tpl-cornell-biochem',
        title: 'Cornell Medical Biochemistry Cue Sheet',
        description:
            '2.5-inch left recall cue column, 7.1mm college rule notes body, and 96pt summary footer optimized for pre-med revision.',
        category: 'Math & Science',
        author: 'BioMed Guild',
        properties: const PaperProperties(
          backgroundColorHex: '#FDFBF7',
          lineColorHex: '#CBD5E1',
          accentColorHex: '#E11D48',
          gridSize: 14.17,
          lineSpacing: 20.13,
          marginTop: 56.0,
          marginBottom: 40.0,
          marginLeft: 56.0,
          marginRight: 40.0,
          hasHeaderArea: true,
          headerHeight: 44.0,
          pageSize: 'A4',
          orientation: 'portrait',
          showPageNumber: true,
        ),
        downloadCount: 528,
        rating: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CustomTemplate(
        id: 'tpl-bullet-habit-tracker',
        title: '7-Day Habit Matrix & Weekly Planner',
        description:
            'Minimalist ivory layout featuring a 7-day habit tracker matrix, top 3 priorities quadrant, and daily time blocks.',
        category: 'Planning',
        author: 'ProductivityHub',
        properties: const PaperProperties(
          backgroundColorHex: '#FAF0F2',
          lineColorHex: '#E2E8F0',
          accentColorHex: '#8B5CF6',
          gridSize: 14.17,
          lineSpacing: 22.0,
          marginTop: 48.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          hasHeaderArea: true,
          headerHeight: 50.0,
          pageSize: 'A4',
          orientation: 'portrait',
          showPageNumber: false,
        ),
        downloadCount: 819,
        rating: 4.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    var filtered = list;
    if (category != null && category.isNotEmpty && category != 'All') {
      filtered = filtered
          .where((t) => t.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return filtered;
  }
}
