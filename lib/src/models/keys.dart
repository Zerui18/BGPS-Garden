import 'package:bgps_garden/src/library.dart';

/// Data Key is used for the id of an [Entity], a [Trail] or a [TrailLocation].
/// Used as an argument when pushing routes in AppNotifier.
abstract class DataKey {
  final int id;
  const DataKey({@required this.id});
  bool operator ==(Object other);
  int get hashCode;
  bool get isValid {
    return id != null;
  }
}

/// A unique identifier for each [Entity]. Consists of its `category` and `id`.
class EntityKey extends DataKey {
  final String category;
  EntityKey({@required this.category, @required int id}) : super(id: id);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EntityKey && category == other.category && id == other.id;
  }

  @override
  int get hashCode => hashValues(category, id);

  @override
  bool get isValid {
    return category != null && id != null;
  }

  @override
  String toString() {
    return 'EntityKey(category: $category, id: $id)';
  }
}

/// A unique identifier for a [Trail]. Wraps its `id`.
class SectionKey extends DataKey {
  SectionKey({@required int id}) : super(id: id);

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SectionKey && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SectionKey(id: $id)';
  }
}

/// A unique identifier for a [TrailLocation]. Wraps its `id`.
class TrailLocationKey extends DataKey {
  final SectionKey trailKey;
  TrailLocationKey({@required this.trailKey, @required int id}) : super(id: id);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TrailLocationKey &&
            trailKey == other.trailKey &&
            id == other.id;
  }

  @override
  int get hashCode => hashValues(trailKey, id);

  @override
  bool get isValid {
    return trailKey.isValid && id != null;
  }

  @override
  String toString() {
    return 'TrailLocationKey(trailId: ${trailKey.id}, id: $id)';
  }
}
