import 'package:bloc_pattern/src/bloc.dart';
import 'package:bloc_pattern/src/bloc_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dependency.dart';

final Map<String, BlocBase> _injectMapBloc = {};
final Map<String, dynamic> _injectMapDependency = {};
 BuildContext _viability;

class BlocProvider extends StatefulWidget {
  BlocProvider({
    Key key,
    @required this.child,
    this.blocs,
    this.dependencies,
  }) : super(key: key);

  final List<Bloc> blocs;
  final List<Dependency> dependencies;
  final Widget child;

  @override
  _BlocProviderListState createState() => _BlocProviderListState();

 
  ///Use to inject a BLoC. If BLoC is not instantiated, it starts a new singleton instance.
  static T injectBloc<T extends BlocBase>() {
    return of<T>(_viability);
  }

///Discards BLoC from application memory
  static void disposeBloc<T extends BlocBase>() {
    try {
      T u = of<T>(_viability);
      u.dispose();
      String typeBloc = T.toString();
      if (_injectMapBloc.containsKey(typeBloc))
        _injectMapBloc.remove([typeBloc]);
    } catch (e) {}
  }

///Use to inject a Dependency. If the Dependency is not instantiated, it starts a new instance. If it is marked as a singleton, the instance persists until the end of the application, or until the [disposeDependency];
  static T injectDependency<T>([Map<String, dynamic> map]) {
    _HelperBlocListProvider provider = _getProvider(_viability);
    String typeBloc = T.toString();
    T dep;
    if (_injectMapDependency.containsKey(typeBloc)) {
      dep = _injectMapDependency[typeBloc];
    } else {
      Dependency d = provider.dependencies
          .firstWhere((dep) => dep.inject is T Function(Map<String, dynamic>));
      dep = d.inject(map);
      if (d.singleton) {
        _injectMapDependency[typeBloc] = dep;
      }
    }
    return dep;
  }

  ///Discards Dependency from application memory
  static void disposeDependency<T>() {
      String typeBloc = T.toString();
      if (_injectMapDependency.containsKey(typeBloc))
        _injectMapDependency.remove([typeBloc]);
  }

  ///This method is deprecated. Use [injectBloc]
  @deprecated
  static T of<T extends BlocBase>(BuildContext context) {
    try {
      _HelperBlocListProvider provider = _getProvider(context);
      BlocBase bloc;
      String typeBloc = T.toString();
      if (_injectMapBloc.containsKey(typeBloc)) {
        bloc = _injectMapBloc[typeBloc];
      } else {
        bloc = provider.blocs
            .where((bloc) => bloc.inject is T Function())
            .toList()[0]
            ?.inject();
        _injectMapBloc[typeBloc] = bloc;
      }
      return bloc;
    } catch (e) {
      throw "Bloc não encontrado";
    }
  }

  static _HelperBlocListProvider _getProvider(BuildContext context) {
    final type = _typeOf<_HelperBlocListProvider>();
    return context.inheritFromWidgetOfExactType(type);
  }

  static Type _typeOf<T>() => T;
}

class _BlocProviderListState extends State<BlocProvider> {
  Type _typeOf<T>() => T;

  @override
  void dispose() {
    for (String key in _injectMapBloc.keys) {
      _injectMapBloc[key].dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HelperBlocListProvider(
      child: Builder(
        builder: (BuildContext context) {
          _viability = context;
          return widget.child;
        },
      ),
      blocs: widget.blocs,
      dependencies: widget.dependencies,
    );
  }
}

class _HelperBlocListProvider extends InheritedWidget {
  final List<Bloc> blocs;
  final List<Dependency> dependencies;
 

  _HelperBlocListProvider({this.dependencies, this.blocs, Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return oldWidget != this;
  }
}