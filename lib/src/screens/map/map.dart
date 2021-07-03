import 'package:bgps_garden/src/library.dart';

extension GlobalKeyExtension on GlobalKey {
  Rect get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null)?.getTranslation();
    if (translation != null && renderObject.paintBounds != null) {
      return renderObject.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({Key key}) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with WidgetsBindingObserver {
  void rebuild() {
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Needed because of a bug with Google Maps not showing, after going back from recents
      // Don't know if this works consistently, 1s randomly chosen
      Future.delayed(const Duration(seconds: 1), rebuild);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<GlobalKey> containerKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];
  List<double> topStart = List.filled(8, 0);
  List<double> leftStart = List.filled(8, 0);
  List<dynamic> locationActions = [];
  List<dynamic> pinLocations = [];
  List<String> sectionNames = [
    "Cactus Garden",
    "Butterfly Garden",
    "Native Garden",
    "Fruit Tree Corner",
    "Vegetable Plot",
    "Ornamental Plants",
  ];

  @override
  Widget build(BuildContext context) {
    pinLocations = [
      [110.0, 63.0],
      [30.0, 80.0],
      [150.0, 80.0],
      [140.0, 100.0],
      [310.0, 40.0],
      [320.0, 70.0],
    ];

    void updatePositions() {
      setState(() {
        for (int i = 0; i < pinLocations.length; i++) {
          topStart[i] = containerKeys[i].globalPaintBounds.top;
          leftStart[i] = containerKeys[i].globalPaintBounds.left;
        }
      });
    }

    List<Widget> stackChildren = [
      Positioned(
        top: MediaQuery.of(context).size.height * 0.05,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image: AssetImage('assets/images/map.png'),
              alignment: Alignment.topCenter
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))
          ),
        ),
      ),
    ];

    List<Widget> pins = [];

    if (containerKeys.length > 0) {
      for (int i = 0; i < pinLocations.length; i++) {
        // print(pinLocations[i][0]);
        stackChildren.add(
          Positioned(
            left: pinLocations[i][0],
            top: MediaQuery.of(context).size.height * 0.05 + pinLocations[i][1],
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.black,
              ),
              key: containerKeys[i],
              height: 30,
              width: 30,
            ),
          ),
        );

        pins.add(
          Positioned(
            top: (topStart[i] == null) ? 0 : (topStart[i] * 1.0) - 40,
            left: (leftStart[i] == null) ? 0 : leftStart[i] * 1.0,
            child: InkWell(
              onTap: () {
                final sectionKey = SectionKey(id: i);
                  context.provide<AppNotifier>(listen: false).push(
                  context: context,
                  routeInfo: RouteInfo(
                    name: sectionNames[i],
                    dataKey: sectionKey,
                    route: CrossFadePageRoute(
                      builder: (context) {
                        return SectionDetailsPage(
                          sectionKey: sectionKey,
                        );
                      },
                    ),
                  ),
                );
              },
              child: Container(
                height: 40,
                child: Row(
                  children: [
                    // Image(image: AssetImage("assets/images/pin.png")),
                    Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        color: Color.fromARGB(172, 255, 255, 255),
                      ),
                      child: Text(sectionNames[i], style: TextStyle(fontSize: 12.0)),
                    ),
                  ],
                )
              ),
            )
          ),
        );
      }
    }
    else {
      setState(() {
        for (int i = 0; i < pinLocations.length; i++) {
          containerKeys.add(GlobalKey());
        }
      });
    }

    return CustomAnimatedSwitcher(
      fadeIn: true,
      child: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              onInteractionEnd: (ScaleEndDetails details) {
                updatePositions();
              },
              onInteractionUpdate: (ScaleUpdateDetails details) {
                updatePositions();
              },
              panEnabled: true,
              minScale: 1.5,
              maxScale: 2.5,
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: stackChildren,
                ),
              ),
            ),
            ...pins
          ],
        ),
      ),
    );
  }
}

/// Updates default markers and polygons of [MapNotifier] by listening to the firebase data stream
class MapDataWidget extends StatefulWidget {
  final Stream<FirebaseData> firebaseDataStream;
  final Widget child;
  const MapDataWidget({
    Key key,
    @required this.firebaseDataStream,
    @required this.child,
  }) : super(key: key);

  @override
  _MapDataWidgetState createState() => _MapDataWidgetState();
}

class _MapDataWidgetState extends State<MapDataWidget> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
