import 'package:bgps_garden/src/library.dart';
import 'dart:collection';

class FirebaseData {
  final EntityMap entities;
  final SectionMap sections;
  final List<HistoricalData> historicalDataList;
  final List<AboutPageData> aboutPageDataList;
  final Set<Polygon> mapPolygons;

  const FirebaseData({
    this.entities,
    this.sections,
    this.historicalDataList,
    this.aboutPageDataList,
    this.mapPolygons,
  });

  static const List<String> sectionNames = [
    'Section A',
    'Section B',
    'Section C',
  ];

  static Entity getEntity({
    @required BuildContext context,
    @required EntityKey key,
    bool listen = true,
  }) {
    return Provider.of<FirebaseData>(
      context,
      listen: listen,
    ).entities[key.category][key.id];
  }

  static SectionData getSection({
    @required BuildContext context,
    @required SectionKey key,
    bool listen = true,
  }) {
    return Provider.of<FirebaseData>(
      context,
      listen: listen,
    ).sections[key];
  }

  /// Needed when the data is a list, to return a map anyways
  static Map _getMap(data) {
    if (data is List)
      return data.asMap();
    else
      return Map.from(data);
  }

  /// Creates an instance of [FirebaseData] based on the `data` supplied.
  /// `data` should be the JSON data of the entire database.
  factory FirebaseData.fromJson(dynamic data) {
    final entities = EntityMap();
    final sections = SectionMap();
    final List<HistoricalData> historicalDataList = [];
    final List<AboutPageData> aboutPageDataList = [];
    final Set<Polygon> mapPolygons = {};

    // Adding entities
    entities.addEntities(
      category: 'flora',
      entitiesJson: _getMap(data['flora']),
    );
    data['fauna'].forEach((category, value) {
      entities.addEntities(
        category: category,
        entitiesJson: _getMap(value),
      );
    });

    // Adding sections
    Map<int, int> sectionToFlora = {};
    _getMap(data['flora']).forEach((floraId, floraValue) {
      sectionToFlora[floraValue['section']] = floraId;
    });

    _getMap(data['sections']).forEach((sectionId, section) {
      final entityKeys = _getMap(section['items']).values.map((item) {
        return EntityKey(category: item['category'], id: item['id']);
      }).toList();
      final sectionData = SectionData(items: entityKeys, name: section['name']);
      final key = SectionKey(id: sectionId);
      sections[key] = sectionData;
    });

    // Add historical data
    _getMap(data['historical']).forEach((key, value) {
      final historicalData = HistoricalData.fromJson(key, value);
      if (historicalData.isValid) historicalDataList.add(historicalData);
    });
    historicalDataList.sort((a, b) => a.id.compareTo(b.id));

    // Add AboutPage data
    _getMap(data['about']).forEach((key, value) {
      final aboutPageData = AboutPageData.fromJson(key, value);
      if (aboutPageData.isValid) aboutPageDataList.add(aboutPageData);
    });
    aboutPageDataList.sort((a, b) => a.id.compareTo(b.id));

    // Add Map Polygons/Outlines for each building
    // _getMap(data['mapPolygons']).forEach((key, value) {
    //   final polygon = generatePolygonFromJson(key, value);
    //   if (polygon != null) mapPolygons.add(polygon);
    // });

    return FirebaseData(
      entities: entities,
      sections: sections,
      historicalDataList: historicalDataList,
      aboutPageDataList: aboutPageDataList,
      mapPolygons: mapPolygons,
    );
  }
}

/// Entities are first grouped by their category, and then by their id in the list.
class EntityMap extends MapView<String, List<Entity>> {
  EntityMap() : super({});

  /// Returns a shallow copy of the current [EntityMap]
  EntityMap clone() {
    final newMap = EntityMap();
    forEach((category, entityList) {
      newMap[category] = entityList;
    });
    return newMap;
  }

  /// Adds entities by their `category`.
  void addEntities({String category, Map entitiesJson}) {
    this[category] = [];
    entitiesJson.forEach((id, data) {
      final entity = Entity.fromJson(category: category, id: id, data: data);
      if (entity.isValid) this[category].add(entity);
    });
  }
}

class SectionData {
  List<EntityKey> items;
  String name;

  SectionData({this.items, this.name});
}

class SectionMap extends MapView<SectionKey, SectionData> {
  SectionMap() : super({});
}
