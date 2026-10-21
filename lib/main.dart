import 'package:flutter/material.dart';

import 'common.dart';
import 'converter_tab.dart';
import 'flows.dart';
import 'native_files.dart';
import 'other_tab.dart';
import 'people_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    NativeFiles.listen(runImport);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final t = await NativeFiles.initialFile();
      if (t != null) runImport(t);
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navKey,
        title: 'سجل المستفيدين',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFFC62828), useMaterial3: true),
        builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجل المستفيدين')),
        body: IndexedStack(index: i, children: const [ConverterTab(), PeopleTab(), OtherTab()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'BBAN محول'),
            NavigationDestination(icon: Icon(Icons.people), label: 'المستفيدين'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'اخرى'),
          ],
        ),
      );
}
