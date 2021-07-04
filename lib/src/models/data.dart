import 'package:bgps_garden/src/library.dart';

/// An [Entity] refers to any flora or fauna, and fauna may include any birds, butterflies, etc.
///
/// Implmenting [Comparable] allows [Entities]s in a list to be sorted without a
/// comparator function, i.e. the `sort()` function can be used without arguments.
/// By defalt, [Entity]s are sorted by their `name`.
class Entity implements Comparable {
  final EntityKey key;
  final String name;
  final String sciName;
  final String description;
  final String smallImage;
  final List<String> images;
  final SectionKey section;

  const Entity({
    this.key,
    this.name,
    this.sciName,
    this.description,
    this.smallImage,
    this.images,
    this.section,
  });

  factory Entity.fromJson({
    @required String category,
    @required int id,
    @required dynamic data,
  }) {
    List<String> images;
    if (data['imageRef'] != null) {
      images = List<String>.from(data['imageRef']);
    } else {
      images = [];
    }

    return Entity(
      key: EntityKey(category: category, id: id),
      name: data['name'],
      sciName: data['sciName'],
      description: data['description'],
      smallImage: data['smallImage'],
      images: images,
      section: SectionKey(id: data['section']),
    );
  }

  /// Returns the level of relevance that the [Entity] matches the `searchTerm`
  int matches(String searchTerm) {
    if (searchTerm.isEmpty || searchTerm == '*') return 3;
    if (Search.matches(name, searchTerm))
      return 2;
    else if (Search.matches(sciName, searchTerm)) return 1;
    return 0;
  }

  bool get isValid {
    return key.isValid &&
        name != null &&
        sciName != null &&
        description != null &&
        smallImage != null &&
        images != null &&
        section != null;
  }

  @override
  int compareTo(other) {
    final Entity typedOther = other;
    return name.compareTo(typedOther.name);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Entity &&
            key == other.key &&
            name == other.name &&
            sciName == other.sciName &&
            description == other.description &&
            smallImage == other.smallImage &&
            listEquals(images, other.images) &&
            section == other.section;
  }

  @override
  int get hashCode {
    return hashValues(
      key,
      name,
      sciName,
      description,
      smallImage,
      hashList(images),
      section,
    );
  }

  @override
  String toString() {
    return 'Entity(category: ${key.category}, id: ${key.id}, name: $name)';
  }
}

/// Used in [Entity], since each [Entity] can be at multiple [TrailLocation]s.
/// This only serves as a wrapper for [TrailLocationKey].
class EntityLocation {
  final TrailLocationKey trailLocationKey;
  const EntityLocation({@required this.trailLocationKey});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EntityLocation && trailLocationKey == other.trailLocationKey;
  }

  @override
  int get hashCode => trailLocationKey.hashCode;

  bool get isValid => trailLocationKey.isValid;
}

class HistoricalData {
  final int id;
  final String title;
  final String description;
  final String image;
  final String newImage;
  final String name;
  final num height;
  final num width;

  const HistoricalData({
    this.id,
    this.title,
    this.description,
    this.image,
    this.newImage,
    this.name,
    this.height,
    this.width,
  });

  factory HistoricalData.fromJson(dynamic key, dynamic data) {
    return HistoricalData(
      id: key,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      image: data['imageRef'] ?? '',
      newImage: data['newImageRef'] ?? '',
      name: data['name'] ?? Random.secure().nextDouble().toString(),
      height: data['height'] ?? 0,
      width: data['width'] ?? 0,
    );
  }

  bool get isValid {
    return id != null &&
        description != null &&
        image != null &&
        newImage != null &&
        name != null &&
        height != null &&
        width != null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HistoricalData &&
            id == other.id &&
            description == other.description &&
            image == other.image &&
            newImage == other.newImage &&
            name == other.name &&
            height == other.height &&
            width == other.width;
  }

  @override
  int get hashCode => hashValues(id, description, image, name, height, width);

  @override
  String toString() {
    return 'HistoricalData(id: $id, description: $description, imageURL: $image)';
  }
}

class AboutPageData {
  final String body;
  final List<AboutPageDropdown> dropdowns;
  final int id;
  final String quote;
  final String title;
  bool isExpanded = false;

  AboutPageData({
    this.body,
    this.dropdowns,
    this.id,
    this.quote,
    this.title,
    this.isExpanded,
  });

  factory AboutPageData.fromJson(int key, dynamic data) {
    return AboutPageData(
      body: data['body'],
      dropdowns: data['dropdowns'] != null
          ? List.from(data['dropdowns'])
              .map((data) {
                return AboutPageDropdown.fromJson(data);
              })
              .where((dropdown) => dropdown.isValid)
              .toList()
          : null,
      id: key,
      quote: data['quote'],
      title: data['title'],
      isExpanded: false,
    );
  }

  bool get isValid {
    return body != null && id != null && title != null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AboutPageData &&
            body == other.body &&
            id == other.id &&
            quote == other.quote &&
            title == other.title &&
            isExpanded == other.isExpanded;
  }

  @override
  int get hashCode => hashValues(body, id, quote, title, isExpanded);
}

class AboutPageDropdown {
  final String title;
  final String body;

  const AboutPageDropdown({this.title, this.body});

  factory AboutPageDropdown.fromJson(dynamic data) {
    return AboutPageDropdown(
      title: data['title'],
      body: data['body'],
    );
  }

  bool get isValid {
    return title != null && body != null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AboutPageData && title == other.title && body == other.body;
  }

  @override
  int get hashCode => hashValues(title, body);
}
