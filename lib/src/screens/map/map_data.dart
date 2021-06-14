import 'package:bgps_garden/src/library.dart';

// const northEastBound = const LatLng(1.328278, 103.807815);
// const southWestBound = const LatLng(1.324095, 103.800954);
const center = const LatLng(1.326580, 103.805239);

Polygon generatePolygonFromJson(String id, dynamic data) {
  final colorInt = int.tryParse('0x30' + data['color'].toString().substring(1));
  final List<LatLng> points = [];
  try {
    final pointsList = List.from(data['points']);
    for (final pointString in pointsList) {
      points.add(LatLng(pointString['latitude'], pointString['longitude']));
    }
  } catch (e) {
    return null;
  }
  if (colorInt == null || points.isEmpty) return null;
  return Polygon(
    polygonId: PolygonId(id),
    strokeWidth: 1,
    strokeColor: Colors.black12,
    fillColor: Color(colorInt),
    points: points,
  );
}

// extension PolygonJson on Polygon {
// dynamic toJson() {
//   double _round(double value) {
//     return (value * 10e6).roundToDouble() / 10e6;
//   }

//   return <String, dynamic>{
//     'color': '#'
//         '${fillColor.red.toRadixString(16).padLeft(2, '0')}'
//         '${fillColor.green.toRadixString(16).padLeft(2, '0')}'
//         '${fillColor.blue.toRadixString(16).padLeft(2, '0')}',
//     'points': points.map((point) {
//       return {
//         'latitude': _round(point.latitude),
//         'longitude': _round(point.longitude),
//       };
//     }).toList(),
//   };
// }
// }

String mapStyle;
//7th Dec 2020, 5:08PM
//stored in assets/data/mapStyle.json, for convenience.
//this is an artifact, because I don't know where to put this without it being ugly.
