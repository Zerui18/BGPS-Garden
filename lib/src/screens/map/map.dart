import 'package:bgps_garden/src/library.dart';

enum DeviceType { Phone, Tablet }

DeviceType getDeviceType() {
  final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
  return data.size.shortestSide < 550 ? DeviceType.Phone : DeviceType.Tablet;
}

bool periodicSyncLabels = false;

void syncLabels() {
  if (periodicSyncLabels) {
    try {
      _MapWidgetState.mapWidget.syncLabelsInternal();
    } catch (e) {
      print(e);
    }
  }
  new Timer(Duration(milliseconds: 200), () {
    syncLabels();
  });
}

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
  static var mapWidget;

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

  void syncLabelsInternal() {
    setState(() {
      for (int i = 0; i < pinLocations.length; i++) {
        topStart[i] = containerKeys[i].globalPaintBounds.top;
        leftStart[i] = containerKeys[i].globalPaintBounds.left;
      }
    });
  }

  @override
  void initState() {
    mapWidget = this;
    syncLabels();
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

  @override
  Widget build(BuildContext context) {
    try {
      pinLocations =
          Provider.of<FirebaseData>(context, listen: false).sectionPinLocations;
    } catch (err) {
      pinLocations = [];
    }

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
                  alignment: Alignment.topCenter),
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
    ];

    List<Widget> pins = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (containerKeys.length > 0) {
      for (int i = 0; i < pinLocations.length; i++) {

        double correctionWidth = 1, correctionHeight = 1;
        if (getDeviceType() == DeviceType.Tablet) {
          if (MediaQuery.of(context).size.height < 1000) {
            correctionWidth = 2;
            correctionHeight = 1.8;
          } else {
            correctionWidth = 2 * 1.3;
            correctionHeight = 1.8 * 1.13;
          }
        } else if (MediaQuery.of(context).size.height < 750) {
          correctionWidth = 1.02;
          correctionHeight = 1.15;
        }

        stackChildren.add(
          Positioned(
            left: pinLocations[i][0] * correctionWidth,
            top: (0.05 * MediaQuery.of(context).size.height +
                    pinLocations[i][1]) *
                correctionHeight,
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
                onTap: () async {
                  final sectionKey = SectionKey(id: i);
                  context.provide<AppNotifier>(listen: false).pop(context);
                  await Future.delayed(
                      const Duration(milliseconds: 300), () {});
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
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.0)),
                            color: isDark
                                ? Color.fromARGB(200, 0, 0, 0)
                                : Color.fromARGB(200, 255, 255, 255),
                          ),
                          child: Text(sectionNames[i],
                              style: TextStyle(fontSize: 12.0)),
                        ),
                      ],
                    )),
              )),
        );
      }
      periodicSyncLabels = true;
    } else {
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
              onInteractionStart: (ScaleStartDetails details) {
                updatePositions();
              },
              onInteractionEnd: (ScaleEndDetails details) {
                updatePositions();
              },
              onInteractionUpdate: (ScaleUpdateDetails details) {
                updatePositions();
              },
              panEnabled: true,
              minScale: 2,
              maxScale: 3,
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
