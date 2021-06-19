import 'package:bgps_garden/src/library.dart';

/// [FilterNotifier] is a single [ChangeNotifier] that deals with anything
/// involving searching, sorting & filtering of [Entity]s.
///
/// Notable properties:
/// - [searchTerm]: set the search term when searching [Entity]s
/// - [selectedTrailKeys]: the list of trail keys that are selected in [FilterDrawer]
/// - [toggleSortByDist()]: toggle the sorting by distance for all [Entity]s
/// - [filter]: accepts an [EntityMap] and returns a sorted & filtered [EntityMap]
/// based on the different filters present in the [FilterNotifier]

class FilterNotifier extends ChangeNotifier {
  // Searching of [Entity]

  final searchBarFocusNode = FocusNode();
  void unfocusSearchBar() {
    searchBarFocusNode?.unfocus();
  }

  String _searchTerm = '';
  String get searchTerm => _searchTerm;
  set searchTerm(String searchTerm) {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  bool get isSearching => _searchTerm.trim().isNotEmpty;

  // Filtering by [Trail]

  /// All trails are selected by default
  List<SectionKey> _selectedTrailKeys = [
    for (final i in [0, 1, 2, 3, 4, 5]) SectionKey(id: i)
  ];
  List<SectionKey> get selectedTrailKeys => _selectedTrailKeys;
  set selectedTrailKeys(List<SectionKey> selectedTrailKeys) {
    _selectedTrailKeys = selectedTrailKeys;
    notifyListeners();
  }

  EntityMap filter(EntityMap entities) {
    final newEntityMap = EntityMap();
    final categories = entities.keys.toList()..sort();
    for (final category in categories) {
      // Filter by trail, no sorting by distance
      if (isSearching) {
        final matchingEntities = <MapEntry<Entity, int>>[];
        final entityList = List.from(entities[category])..sort();
        for (final entity in entityList) {
          if (true) {
            final relevance = entity.matches(searchTerm);
            if (relevance != 0) {
              matchingEntities.add(MapEntry(entity, relevance));
            }
          }
        }
        // From highest to lowest
        matchingEntities.sort((a, b) => b.value.compareTo(a.value));
        newEntityMap[category] =
            matchingEntities.map((entry) => entry.key).toList();
      } else {
        newEntityMap[category] = entities[category].toList();
        newEntityMap[category].sort();
      }
    }
    return newEntityMap;
  }
}

class EntityDistance implements Comparable {
  final EntityKey key;
  final String name;
  final double distance;
  const EntityDistance({this.key, this.name, this.distance});

  @override
  int compareTo(other) {
    final EntityDistance typedOther = other;
    final int comparison = distance.compareTo(typedOther.distance);
    if (comparison == 0) return name.compareTo(typedOther.name);
    return comparison;
  }
}

class Search {
  /// Checks if the start of each word within [text] starts with the [pattern]
  /// Uses spaces to separate between different words in [text]
  static bool matches(String text, String pattern) {
    assert(pattern.isNotEmpty);
    bool check = true;
    final m = text.length - pattern.length + 1;
    for (int i = 0; i < m; i++) {
      if (check) {
        if (text
            .substring(i)
            .toLowerCase()
            .startsWith(pattern.trim().toLowerCase())) {
          return true;
        }
        check = false;
      }
      if (text[i] == ' ') check = true;
    }
    return false;
  }
}
