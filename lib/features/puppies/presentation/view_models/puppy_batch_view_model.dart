import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../domain/repositories/i_puppy_repository.dart';

/// One editable row of the batch form. [id] is null for a puppy that does not
/// exist yet (insert) and non-null for a puppy already persisted (update).
/// Carrying the id is what makes the save idempotent instead of duplicating on
/// every edit — see F04 verdict 4.1.
class PuppyBatchItem {
  int? id;
  String name;
  String sex; // 'female' | 'male'
  String color;
  double birthWeight;

  PuppyBatchItem({
    this.id,
    required this.name,
    required this.sex,
    required this.color,
    required this.birthWeight,
  });
}

/// View model for the batch creation/edition screen of a litter's puppies.
///
/// Loads the real puppies of a litter from the repository (never a hardcoded
/// mock) and resolves the species-specific label ("Chiot N" / "Chaton N") from
/// the kennel, so no species string is ever hardcoded in the UI.
///
/// Save is idempotent: items carry their id, and the repository's batch save
/// distinguishes insert (id null) from update (id present) and deletes puppies
/// absent from the payload. After a successful save the view model reloads
/// from the source of truth so newly inserted puppies get their assigned ids.
class PuppyBatchViewModel extends ChangeNotifier {
  PuppyBatchViewModel({
    required IKennelRepository kennelRepository,
    required IPuppyRepository puppyRepository,
  }) : _kennelRepository = kennelRepository,
       _puppyRepository = puppyRepository;

  final IKennelRepository _kennelRepository;
  final IPuppyRepository _puppyRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Species of the kennel, resolved on load. Defaults to 'dog' until
  /// [loadLitterPuppies] completes. Drives [_youngLabel].
  String _species = 'dog';
  String get species => _species;

  List<PuppyBatchItem> _items = [];
  List<PuppyBatchItem> get items => _items;

  /// Whether a load or save is running or has populated [items]. Used by the
  /// screen to distinguish the empty-but-loaded state (show the add button)
  /// from the not-yet-loaded state.
  bool get isReady => _items.isNotEmpty;

  /// Species-specific noun for a young animal, singular lowercase ("chiot" or
  /// "chaton"). Exposed so the screen never hardcodes a species string.
  String get youngNoun => _species == 'cat' ? 'chaton' : 'chiot';

  /// Plural form of [youngNoun] ("chiots" / "chatons").
  String get youngNounPlural => '${youngNoun}s';

  /// Capitalized singular noun ("Chiot" / "Chaton"), for sentence starts.
  String get youngNounCapitalized =>
      '${youngNoun[0].toUpperCase()}${youngNoun.substring(1)}';

  /// Default name for the Nth row, e.g. "Chiot 1" or "Chaton 3".
  String _youngLabel(int n) => '$youngNounCapitalized $n';

  /// Loads the real puppies of [litterId] from the repository, resolving the
  /// species label from the kennel first. A litter with no puppies yields an
  /// empty form (the screen offers an "add" button) — no mock pre-fill.
  Future<void> loadLitterPuppies(int litterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final kennel = await _kennelRepository.getKennel();
      _species = (kennel?.species == 'cat') ? 'cat' : 'dog';

      final existing = await _puppyRepository.getPuppies(litterId);
      _items = existing
          .map(
            (p) => PuppyBatchItem(
              id: p.id,
              name: p.name,
              sex: p.sex,
              color: p.color ?? '',
              birthWeight: p.birthWeight ?? 0.0,
            ),
          )
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends a new row with a default species-specific name.
  void addItem() {
    _items.add(
      PuppyBatchItem(
        name: _youngLabel(_items.length + 1),
        sex: 'female',
        color: '',
        birthWeight: 0.0,
      ),
    );
    notifyListeners();
  }

  /// Removes the row at [index]. A single remaining row can still be removed
  /// (an empty form is valid — the save then clears the litter's puppies).
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateSex(int index, String sex) {
    _items[index].sex = sex;
    notifyListeners();
  }

  /// Saves the whole batch idempotently, then reloads from the repository so
  /// newly inserted puppies pick up their server-assigned ids.
  ///
  /// Returns true on success, false on failure (the caller surfaces a SnackBar).
  Future<bool> saveBatch(int litterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final puppiesToSave = _items
          .map(
            (item) => Puppy(
              id: item.id,
              litterId: litterId,
              name: item.name.trim().isEmpty
                  ? _youngLabel(1)
                  : item.name.trim(),
              sex: item.sex,
              color: item.color.trim().isEmpty ? null : item.color.trim(),
              status: 'available',
              birthWeight: item.birthWeight,
            ),
          )
          .toList();

      await _puppyRepository.savePuppiesBatch(litterId, puppiesToSave);

      // Reload the items from the source of truth: new puppies now carry their
      // ids, so a second save without changes is a no-op (idempotent). The
      // species is already known — no need to re-read the kennel here.
      final fresh = await _puppyRepository.getPuppies(litterId);
      _items = fresh
          .map(
            (p) => PuppyBatchItem(
              id: p.id,
              name: p.name,
              sex: p.sex,
              color: p.color ?? '',
              birthWeight: p.birthWeight ?? 0.0,
            ),
          )
          .toList();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
