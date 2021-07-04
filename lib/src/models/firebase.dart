import 'package:bgps_garden/src/library.dart';
import 'dart:collection';
import 'dart:convert';

final List<String> sectionNames = [
  "Desert Plants",
  "Butterfly Garden",
  "Native Plants",
  "Fruit Trees",
  "Ornamental Plants",
  "Community Garden",
  "Fern Garden",
  "Herbs & Spices",
];

class FirebaseData {
  final EntityMap floraEntities;
  final EntityMap faunaEntities;
  final SectionMap sections;
  final List<HistoricalData> historicalDataList;
  final List<AboutPageData> aboutPageDataList;
  final Set<Polygon> mapPolygons;
  final List<dynamic> sectionPinLocations;

  void printObject(Object object) {
    // Encode your object and then decode your object to Map variable
    Map jsonMapped = json.decode(json.encode(object)); 

    // Using JsonEncoder for spacing
    JsonEncoder encoder = new JsonEncoder.withIndent('  '); 

    // encode it to string
    String prettyPrint = encoder.convert(jsonMapped); 

    // print or debugPrint your object
    debugPrint(prettyPrint); 
  }


  const FirebaseData(
      {this.floraEntities,
      this.faunaEntities,
      this.sections,
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
      final data = Provider.of<FirebaseData>(
        context,
        listen: listen,
      );
      if (data.floraEntities.containsKey(key.category))
        return data.floraEntities[key.category].firstWhere((entity) => entity.key.id == key.id);
      else
        return data.faunaEntities[key.category].firstWhere((entity) => entity.key.id == key.id);
    } catch (e) {
      print("[FirebaseData] tried to call getEntity with nonexistent key $key");
      Provider.of<FirebaseData>(
        context,
        listen: false,
      ).floraEntities.forEach((key, value) => value.forEach((entity) => print(entity)));
    }
  }

  static SectionMap getSections({
    @required BuildContext context,
    @required SectionKey key,
    bool listen = true,
  }) {
    return Provider.of<FirebaseData>(
      context,
      listen: listen,
    ).sections;
  }

  static List<Entity> getEntitiesOfSection({
    @required BuildContext context,
    @required String key,
    bool listen = true,
  }) {
    return Provider.of<FirebaseData>(
      context,
      listen: listen,
    ).floraEntities[key] ?? [];
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
    final floraEntities = EntityMap();
    final faunaEntities = EntityMap();
    final sections = SectionMap();
    final List<HistoricalData> historicalDataList = [];
    final List<AboutPageData> aboutPageDataList = [];
    final Set<Polygon> mapPolygons = {};
    final List<dynamic> pinPositions = [];

    Map<int, List<EntityKey>> sectionToFlora = {};
    Map<int, List<Map>> sectionToFloraData = {};

    // Add fauna entities
    data['fauna'].forEach((category, value) {
      faunaEntities.addEntities(
        category: category,
        entitiesJson: _getMap(value),
      );
    });

    // Adding sections
    _getMap(data['flora']).forEach((floraId, floraValue) {
      int sectionId = floraValue['section'];
      if (!sectionToFlora.containsKey(sectionId)) {
        sectionToFlora[sectionId] = [];
      }
      if (!sectionToFloraData.containsKey(sectionId)) {
        sectionToFloraData[sectionId] = [];
      }
      sectionToFlora[sectionId].add(EntityKey(category: 'flora', id: floraId));
      dynamic flora = _getMap(floraValue);
      flora['id'] = floraId;
      sectionToFloraData[sectionId].add(flora);
    });

    // Add flora entities
    sectionToFloraData.forEach((section, floras) {
      floraEntities.addEntities(
        category: sectionNames[section],
        entitiesJson:
            Map.fromIterable(floras, key: (f) => f['id'], value: (f) => f),
      );
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
        floraEntities: floraEntities,
        faunaEntities: faunaEntities,
        sections: sections,
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
