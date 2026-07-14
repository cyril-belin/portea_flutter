import 'package:portea_client/portea_client.dart';

abstract class IWeighingRepository {
  Future<List<WeighingEntry>> getWeighings(int puppyId);
  Future<void> addWeighing(WeighingEntry entry);
  Future<void> addWeighings(List<WeighingEntry> entries);
}
