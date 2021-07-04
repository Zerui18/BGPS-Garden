import 'package:bgps_garden/src/library.dart';
import 'dart:collection';

class FirebaseData {
  final EntityMap entities;
  final SectionMap sections;
  final List<String> sectionNames;
  final List<HistoricalData> historicalDataList;
  final List<AboutPageData> aboutPageDataList;
  final Set<Polygon> mapPolygons;
  final List<dynamic> sectionPinLocations;

  const FirebaseData(
      {this.entities,
      this.sections,
      this.sectionNames,
      this.historicalDataList,
      this.aboutPageDataList,
      this.mapPolygons,
      this.sectionPinLocations});

  static Entity getEntity({
    @required BuildContext context,
    @required EntityKey key,
    bool listen = true,
  }) {
    try {
      return Provider.of<FirebaseData>(
        context,
        listen: listen,
      ).entities[key.category][key.id];
    } catch (e) {
      print("entity error");
      print(Provider.of<FirebaseData>(
        context,
        listen: listen,
      ).entities);
      print(e);
    }
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

  static List<String> getSectionNames(
      {@required BuildContext context, bool listen = true}) {
    final provider = Provider.of<FirebaseData>(context, listen: listen);
    return provider != null ? provider.sectionNames : [];
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
    final List<String> sectionNames = [];
    final List<HistoricalData> historicalDataList = [];
    final List<AboutPageData> aboutPageDataList = [];
    final Set<Polygon> mapPolygons = {};
    final List<dynamic> pinPositions = [];

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
    Map<int, List<EntityKey>> sectionToFlora = {};
    _getMap(data['flora']).forEach((floraId, floraValue) {
      int sectionId = floraValue['section'];
      if (!sectionToFlora.containsKey(sectionId)) {
        sectionToFlora[sectionId] = [];
      }
      sectionToFlora[sectionId].add(EntityKey(category: 'flora', id: floraId));
    });

    data['fauna'].forEach((category, value) {
      _getMap(value).forEach((faunaId, faunaValue) {
        int sectionId = faunaValue['section'];
        if (!sectionToFlora.containsKey(sectionId)) {
          sectionToFlora[sectionId] = [];
        }
        sectionToFlora[sectionId]
            .add(EntityKey(category: 'fauna', id: faunaId));
      });
    });

    _getMap(data['sections']).forEach((sectionId, section) {
      final sectionData = SectionData(
          items: sectionToFlora.containsKey(sectionId)
              ? sectionToFlora[sectionId]
              : [],
          name: section['name']);
      final key = SectionKey(id: sectionId);
      sections[key] = sectionData;
      sectionNames.add(section['name']);
      pinPositions.add([section['pin'][0] + .0, section['pin'][1] + .0]);
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

    return FirebaseData(
        entities: entities,
        sections: sections,
        sectionNames: sectionNames,
        historicalDataList: historicalDataList,
        aboutPageDataList: aboutPageDataList,
        mapPolygons: mapPolygons,
        sectionPinLocations: pinPositions);
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
