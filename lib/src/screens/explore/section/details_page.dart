import 'package:bgps_garden/src/library.dart';

class SectionDetailsPage extends StatefulWidget {
  final SectionKey sectionKey;
  const SectionDetailsPage({
    Key key,
    @required this.sectionKey,
  }) : super(key: key);

  @override
  _SectionDetailsPageState createState() => _SectionDetailsPageState();
}

class _SectionDetailsPageState extends State<SectionDetailsPage> {
  bool _init = false;
  AppNotifier _appNotifier;
  final _scrollController = ScrollController();

  void stateListener() {
    if (context != null &&
        _appNotifier.state == 0 &&
        _appNotifier.routes.isNotEmpty) {
      final bottomSheetNotifier = Provider.of<BottomSheetNotifier>(
        context,
        listen: false,
      );
      if (_scrollController.hasClients &&
          bottomSheetNotifier.animation.value > 10) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appNotifier = context.provide<AppNotifier>(listen: false)
      ..addListener(stateListener);
    if (!_init) {
      _appNotifier.updateScrollController(
        context: context,
        dataKey: widget.sectionKey,
        scrollController: _scrollController,
      );
      _init = true;
    }
  }

  @override
  void dispose() {
    _appNotifier.removeListener(stateListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSheetNotifier =
        context.provide<BottomSheetNotifier>(listen: false);
    List<EntityKey> entityKeys = FirebaseData.getSection(
      context: context,
      key: widget.sectionKey,
    ).items;
    entityKeys.sort((a, b) {
      return a.id.compareTo(b.id);
    });
    return Padding(
      padding: EdgeInsets.only(
        bottom: Sizes.kBottomBarHeight + MediaQuery.of(context).padding.bottom,
      ),
      child: Material(
        color: Theme.of(context).bottomAppBarColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: NeverScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: const TopPaddingSpace(),
            ),
            SliverToBoxAdapter(
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
                  child: Text(
                    FirebaseData.sectionNames[widget.sectionKey.id],
                    style: Theme.of(context).textTheme.headline4,
                    textAlign: TextAlign.center,
                  ),
                ),
                onTap: () {
                  if (bottomSheetNotifier.animation.value < 8) {
                    bottomSheetNotifier.animateTo(
                      bottomSheetNotifier.snappingPositions.value.last,
                    );
                  } else {
                    bottomSheetNotifier.animateTo(
                      bottomSheetNotifier.snappingPositions.value.first,
                    );
                  }
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              sliver: SliverFixedExtentList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return EntityListRow(
                      entity: FirebaseData.getEntity(
                          context: context, key: entityKeys[index]),
                      categoriesEntityCount: {},
                      index: index,
                      scrollController: _scrollController,
                    );
                  },
                  childCount: entityKeys.length,
                ),
                itemExtent: 104,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class LocationListRow extends StatefulWidget {
//   final TrailLocation location;
//   final int index;
//   final ScrollController scrollController; // For getting scroll position
//   const LocationListRow({
//     Key key,
//     @required this.location,
//     @required this.index,
//     @required this.scrollController,
//   }) : super(key: key);

//   @override
//   _LocationListRowState createState() => _LocationListRowState();
// }

// class _LocationListRowState extends State<LocationListRow> {
//   static const _rowHeight = 84.0;
//   Animation<double> _bottomSheetAnimation;
//   Tween<double> _topSpaceTween;
//   Tween<double> _contentOffsetTween;

//   double _getSourceTop() {
//     if (!widget.scrollController.hasClients) return null;
//     return _topSpaceTween.evaluate(_bottomSheetAnimation) +
//         _rowHeight * widget.index -
//         widget.scrollController.offset;
//   }

//   double _getContentOffset() {
//     return _contentOffsetTween.evaluate(_bottomSheetAnimation);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final topPadding = MediaQuery.of(context).padding.top;
//     final height = MediaQuery.of(context).size.height;

//     _bottomSheetAnimation = Tween<double>(
//       begin: 0,
//       end: 1 / (height - Sizes.kBottomHeight),
//     ).animate(
//       Provider.of<BottomSheetNotifier>(context, listen: false).animation,
//     );
//     _topSpaceTween = Tween<double>(
//       begin: 72 + topPadding,
//       end: 72,
//     );
//     _contentOffsetTween = Tween(
//       begin: topPadding + 16 - (_rowHeight - 64) / 2,
//       end: 16 - (_rowHeight - 64) / 2,
//     );

//     final List<String> names = [];
//     for (final position in widget.location.entityPositions) {
//       final entity =
//           FirebaseData.getEntity(context: context, key: position.entityKey);
//       if (entity != null) names.add(entity.name);
//     }
//     return InkWell(
//       child: Hero(
//         tag: widget.location.key,
//         child: InfoRow(
//           height: _rowHeight,
//           image: widget.location.smallImage,
//           title: widget.location.name,
//           subtitle: names.join(', '),
//           subtitleStyle: Theme.of(context).textTheme.caption.copyWith(
//                 fontSize: 13.5,
//               ),
//           tapToAnimate: false,
//         ),
//       ),
//       onTap: () {
//         context.provide<AppNotifier>(listen: false).push(
//               context: context,
//               routeInfo: RouteInfo(
//                 name: widget.location.name,
//                 dataKey: widget.location.key,
//                 route: SlidingUpPageRoute(
//                   getSourceTop: _getSourceTop,
//                   sourceHeight: _rowHeight,
//                   getContentOffset: _getContentOffset,
//                   builder: (context) {
//                     return TrailLocationOverviewPage(
//                       trailLocationKey: widget.location.key,
//                     );
//                   },
//                 ),
//               ),
//             );
//       },
//     );
//   }
// }
