part of globallocation;

@visibleForTesting
typedef Location LocationFactory();

@visibleForTesting
void mockLocation(LocationFactory mock) {
  _createLocation = mock;
}

LocationFactory _createLocation = () => Location();

/// The actual inherited widget for the context
class LocationContext extends InheritedWidget {
  final Position currentLocation;
  final Position lastLocation;
  final String error;
  ///

  LocationContext._({
    @required this.currentLocation,
    this.lastLocation,
    this.error,
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  static Widget around(Widget child, {Key key}) {
    return _LocationContextWrapper(child: child, key: key);
  }

  static LocationContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocationContext>();
  }

  @override
  bool updateShouldNotify(LocationContext oldWidget) {
    return currentLocation != oldWidget.currentLocation ||
        lastLocation != oldWidget.lastLocation ||
        error != oldWidget.error;
  }
}

/// Use this widget to automagically wrap the context
class _LocationContextWrapper extends StatefulWidget {
  final Widget child;

  _LocationContextWrapper({Key key, this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LocationContextWrapperState();
}

class _LocationContextWrapperState extends State<_LocationContextWrapper> {
  final Location _location = Location();

  String _error;

  Position _currentLocation;
  Position _lastLocation;

  StreamSubscription<LocationData> _locationChangedSubscription;

  @override
  void initState() {
    super.initState();

    _locationChangedSubscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
          final Position nextLocation = Position._fromMap(currentLocation);
          setState(() {
            _error = null;
            _lastLocation = _currentLocation;
            _currentLocation = nextLocation;
          });
        });

    initLocation();
  }

  @override
  void dispose() {
    _locationChangedSubscription?.cancel();
    super.dispose();
  }

  void initLocation() async {
    try {
      final LocationData result = await _location.getLocation();

      setState(() {
        _error = null;
        _lastLocation = Position._fromMap(result);
        _currentLocation = _lastLocation;
      });
    } on PlatformException catch (e) {
      setState(() {
        if (e.code == 'PERMISSION_DENIED') {
          _error = 'Permisos de Localización denegados';
        } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
          _error =
          'Permisos denegados. Por favor abra las configuraciones de la aplicacion y habilite los permisos de Localización.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocationContext._(
      lastLocation: _lastLocation,
      currentLocation: _currentLocation,
      error: _error,
      child: widget.child,
    );
  }
}
