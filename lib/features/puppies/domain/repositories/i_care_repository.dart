import 'package:portea_client/portea_client.dart';

abstract class ICareRepository {
  Future<List<CareEntry>> getCareEntries({int? puppyId, int? litterId});
  Future<void> addCareEntry(CareEntry entry);
  Future<List<CareEntry>> getUpcomingReminders(int limit);
}
