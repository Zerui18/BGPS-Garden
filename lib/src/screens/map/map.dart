import 'package:bgps_garden/src/library.dart';

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

  @override
  Widget build(BuildContext context) {
    return CustomAnimatedSwitcher(
      fadeIn: true,
      child: SafeArea(
          child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 2,
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.contain,
                        image: AssetImage('assets/images/map.png'),
                        alignment: Alignment.topCenter),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ))),
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
