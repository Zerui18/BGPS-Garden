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
  new Timer(Duration(milliseconds: 17), () {
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

  @override
  void initState() {
    mapWidget = this;
    syncLabels();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    periodicSyncLabels = false;
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
  List<GlobalKey> pinKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];
  List<dynamic> locationActions = [];
  List<dynamic> pinLocations = [];
  // List<String> sectionNames = [
  //   "Desert Plants",
  //   "Butterfly Garden",
  //   "Native Plants",
  //   "Fruit Trees",
  //   "Ornamental Plants",
  //   "Community Garden",
  //   "Fern Garden",
  //   "Herbs & Spices",
  // ];
  TransformationController _transformationController = TransformationController();
  GlobalKey imageKey = GlobalKey();
  double viewerScale = 0;

  void syncLabelsInternal() {
    setState(() {
      viewerScale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<double> notifier = ValueNotifier(0);

    try {
      pinLocations = Provider.of<FirebaseData>(context, listen: false).sectionPinLocations;
    } catch (err) {
      pinLocations = [];
    }

    List<Widget> positioningBoxes = [];
    List<Widget> pins = [];

    for (int i = 0; i < pinLocations.length; i++) {
      if (imageKey.globalPaintBounds == null) break;

      positioningBoxes.add(Positioned(
        left: imageKey.globalPaintBounds.width * pinLocations[i][0],
        top: imageKey.globalPaintBounds.height * pinLocations[i][1],
        height: 20,
        width: 20,
        child: Container(
          key: containerKeys[i],
          // decoration: BoxDecoration(color: Colors.black),
        ),
      ),);

      if (containerKeys[i].globalPaintBounds == null) continue;

      pins.add(AnimatedBuilder(
        animation: notifier,
        builder: (BuildContext context, Widget widget) {
          return Positioned(
            left:
              containerKeys[i].globalPaintBounds.left
              - (pinKeys[i].globalPaintBounds == null ? 0 : pinKeys[i].globalPaintBounds.width / 2)
              ,
            top:
              containerKeys[i].globalPaintBounds.top
              - (40 / viewerScale)
              - (pinKeys[i].globalPaintBounds == null ? 0 : pinKeys[i].globalPaintBounds.height / 2)
              - 24 // only used if there are pin icons
              ,
            key: pinKeys[i],
            child: InkWell(
              onTap: () async {
                final sectionKey = SectionKey(id: i);
                context.provide<AppNotifier>(listen: false).pop(context);
                await Future.delayed(const Duration(milliseconds: 300), () {});
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
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(128, 128, 128, 128),
                          blurRadius: 4.0, // soften the shadow
                          // spreadRadius: 7.0, //extend the shadow
                          offset: Offset(
                            2.0, // Move to right 10  horizontally
                            2.0, // Move to bottom 5 Vertically
                          ),
                        ),
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                      color: Color.fromARGB(192, 255, 255, 255),
                    ),
                    child: Text(sectionNames[i], style: TextStyle(color: Colors.black,),),
                  ),
                  Image(
                    image: AssetImage("assets/images/pin.png"),
                    height: 54,
                  ),
                ],
              ),
            ),
          );
        }
      ),);
    }

    periodicSyncLabels = true;

    return CustomAnimatedSwitcher(
      fadeIn: true,
      child: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              onInteractionUpdate: (ScaleUpdateDetails details) {
                notifier.value = containerKeys[0].globalPaintBounds.left;
              },
              onInteractionEnd: (ScaleEndDetails details) {
                notifier.value = containerKeys[0].globalPaintBounds.left;
              },
              minScale: 1,
              maxScale: 2.5,
              constrained: false,
              scaleEnabled: true,
              child: Stack(
                children: [
                  Container(
                    width: 800,
                    height: 1000,
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 800,
                    key: imageKey,
                    child: Image(
                      image: AssetImage("assets/images/map.png"),
                    ),
                  ),
                  ...positioningBoxes,
                ],
              )
            ),
            ...pins,
          ],
        ),
      ),
    );
  }
}
