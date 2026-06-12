import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/turnos/services/checklist_progress_service.dart';
import '../controllers/auth_controller.dart';

final checklistProgressServiceProvider = Provider<ChecklistProgressService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ChecklistProgressService(prefs);
});
