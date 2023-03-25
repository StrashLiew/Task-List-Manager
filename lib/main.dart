import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_list_manager/ui/page_done.dart';
import 'package:task_list_manager/ui/page_task.dart';
import 'package:task_list_manager/ui/page_dailylist.dart';
import 'package:firebase_core/firebase_core.dart';

Future<Null> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _currentUser = await _signInAnonymously();

  runApp(new TaskistApp());
}

final FirebaseAuth _auth = FirebaseAuth.instance;

User? _currentUser;

Future<User?> _signInAnonymously() async {
  final userCredential = await _auth.signInAnonymously();
  User? user = userCredential.user;
  return user;
}

class HomePage extends StatefulWidget {
  final User user;

  HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class TaskistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Taskist",
      home: HomePage(
        user: _currentUser!,
      ),
      theme: new ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;

  final List<Widget> _children = [
    DonePage(
      user: _currentUser!,
    ),
    TaskPage(
      user: _currentUser!,
    ),
    DailyListPage(
      user: _currentUser!,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        fixedColor: Colors.deepPurple,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: new Icon(FontAwesomeIcons.calendarCheck),
              label: ""),
          BottomNavigationBarItem(
              icon: new Icon(FontAwesomeIcons.calendar), label: ""),
          BottomNavigationBarItem(
              icon: new Icon(FontAwesomeIcons.slidersH), label: "")
        ],
      ),
      body: _children[_currentIndex],
    );
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);  // to re-show bars
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);  // to hide bars
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}