import 'package:bgps_garden/src/library.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({Key key}) : super(key: key);

  @override
  _FilterDrawerState createState() => _FilterDrawerState();
}

enum DistanceSortingState {
  none,
  loading,
  locationPermissionDenied,
  locationOff,
}

class _FilterDrawerState extends State<FilterDrawer> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    return Drawer(
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, topPadding + 16, 0, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height - topPadding - 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Filter',
                    style: Theme.of(context).textTheme.headline3,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      child: Text(
                        'Sections',
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                    Selector<FilterNotifier, List<SectionKey>>(
                      selector: (context, filterNotifier) {
                        return filterNotifier.selectedTrailKeys;
                      },
                      builder: (context, selectedTrailKeys, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              FirebaseData.getSectionNames(context: context)
                                  .asMap()
                                  .entries
                                  .map((trailEntry) {
                            return CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: !selectedTrailKeys.every((key) {
                                return key.id != trailEntry.key;
                              }),
                              title: Text(
                                trailEntry.value,
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                              checkColor: Theme.of(context).canvasColor,
                              onChanged: (value) {
                                final filterNotifier =
                                    Provider.of<FilterNotifier>(
                                  context,
                                  listen: false,
                                );
                                final newTrailKeys = List<SectionKey>.from(
                                  filterNotifier.selectedTrailKeys,
                                );
                                final trailKey = SectionKey(id: trailEntry.key);
                                newTrailKeys.remove(trailKey);
                                if (value) {
                                  newTrailKeys.add(trailKey);
                                }
                                filterNotifier.selectedTrailKeys = newTrailKeys;
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
