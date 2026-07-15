import 'package:portea_client/portea_client.dart';

class MockDatabase {
  MockDatabase._();

  static final MockDatabase instance = MockDatabase._();

  Kennel? kennel = Kennel(
    name: "L'Élevage des Terres Dorées",
    species: "dog",
    affix: "des Terres Dorées",
    siret: "12345678900012",
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  final List<Breeder> breeders = [
    Breeder(
      id: 1,
      name: "Salsa",
      sex: "female",
      breed: "Golden Retriever",
      birthDate: DateTime.now().subtract(const Duration(days: 3 * 365)),
      chipNumber: "250268739182736",
      status: "active",
      kennelId: 1,
    ),
    Breeder(
      id: 2,
      name: "Ramses",
      sex: "male",
      breed: "Golden Retriever",
      birthDate: DateTime.now().subtract(const Duration(days: 4 * 365)),
      chipNumber: "250268739182999",
      status: "active",
      kennelId: 1,
    ),
  ];

  final List<Litter> litters = [
    Litter(
      id: 1,
      motherId: 1,
      fatherId: 2,
      birthDate: DateTime.now().subtract(
        const Duration(days: 21),
      ), // 3 weeks old
      kennelId: 1,
      isActive: true,
    ),
  ];

  final List<Puppy> puppies = [
    Puppy(
      id: 1,
      litterId: 1,
      name: "Chiot 1 (Orphée)",
      sex: "female",
      color: "Fauve clair",
      status: "available",
      birthWeight: 350.0,
    ),
    Puppy(
      id: 2,
      litterId: 1,
      name: "Chiot 2 (Onyx)",
      sex: "male",
      color: "Fauve doré",
      status: "reserved",
      birthWeight: 380.0,
      buyerName: "Jean Dupont",
      buyerPhone: "0601020304",
      buyerEmail: "jean.dupont@email.com",
      buyerAddress: "10 Rue de la Paix, Paris",
    ),
    Puppy(
      id: 3,
      litterId: 1,
      name: "Chiot 3 (Oscar)",
      sex: "male",
      color: "Sable",
      status: "sold",
      birthWeight: 320.0,
    ),
  ];

  final List<WeighingEntry> weighings = [
    // Chiot 1
    WeighingEntry(
      id: 1,
      puppyId: 1,
      weighedAt: DateTime.now().subtract(const Duration(days: 21)),
      weightGrams: 350,
    ),
    WeighingEntry(
      id: 2,
      puppyId: 1,
      weighedAt: DateTime.now().subtract(const Duration(days: 14)),
      weightGrams: 750,
    ),
    WeighingEntry(
      id: 3,
      puppyId: 1,
      weighedAt: DateTime.now().subtract(const Duration(days: 7)),
      weightGrams: 1200,
    ),
    WeighingEntry(
      id: 4,
      puppyId: 1,
      weighedAt: DateTime.now(),
      weightGrams: 1800,
    ),

    // Chiot 2
    WeighingEntry(
      id: 5,
      puppyId: 2,
      weighedAt: DateTime.now().subtract(const Duration(days: 21)),
      weightGrams: 380,
    ),
    WeighingEntry(
      id: 6,
      puppyId: 2,
      weighedAt: DateTime.now().subtract(const Duration(days: 14)),
      weightGrams: 820,
    ),
    WeighingEntry(
      id: 7,
      puppyId: 2,
      weighedAt: DateTime.now().subtract(const Duration(days: 7)),
      weightGrams: 1300,
    ),

    // Chiot 3
    WeighingEntry(
      id: 8,
      puppyId: 3,
      weighedAt: DateTime.now().subtract(const Duration(days: 21)),
      weightGrams: 320,
    ),
    WeighingEntry(
      id: 9,
      puppyId: 3,
      weighedAt: DateTime.now().subtract(const Duration(days: 14)),
      weightGrams: 690,
    ),
  ];

  final List<CareEntry> careEntries = [
    CareEntry(
      id: 1,
      type: "deworming",
      product: "Milbemax Chiot",
      appliedAt: DateTime.now().subtract(const Duration(days: 7)),
      litterId: 1,
      reminderAt: DateTime.now().add(const Duration(days: 7)),
      notes: "Soin groupé effectué sur toute la portée",
    ),
    CareEntry(
      id: 2,
      type: "vaccine",
      product: "CHPPIL primer",
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
      puppyId: 1,
      notes: "Aucune réaction indésirable",
    ),
  ];

  bool premiumUser = false;
  String themeMode = 'system';
}
