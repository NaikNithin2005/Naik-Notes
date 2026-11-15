import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';
import 'handwriting_recognition_service.dart';

/// Global provider for the HandwritingRecognitionService.
final handwritingRecognitionServiceProvider =
    Provider<HandwritingRecognitionService>((ref) {
      final searchRepo = ref.watch(pageSearchRepositoryProvider);
      return HandwritingRecognitionService(searchRepository: searchRepo);
    });
