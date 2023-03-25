import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:task_list_manager/utils/app_theme.dart';
import 'package:task_list_manager/utils/extensions.dart';
import 'package:task_list_manager/model/calendar/calendar_timeline.dart';
import 'package:task_list_manager/utils/diamond_fab.dart';
import 'package:task_list_manager/utils/constants.dart';
import 'package:task_list_manager/utils/buttons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:async';
class DailyListPage extends StatefulWidget {

  final User user;
  
  DailyListPage({Key? key, required this.user}) : super(key: key);
  @override
  _DailyListPageState createState() => _DailyListPageState();
}

class _DailyListPageState extends State<DailyListPage> {
  DateTime datePicked = DateTime.now();

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _saving = false;
  var formatter = new DateFormat('yyyy-MM-dd');
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = new Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final ValueNotifier<int> totalTask = ValueNotifier(0);
  final ValueNotifier<List<DocumentSnapshot>> documents =
      ValueNotifier<List<DocumentSnapshot>>([]);
  TextEditingController titleController = TextEditingController();


  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = new GlobalKey<ScaffoldMessengerState>();

  Future<Null> initConnectivity() async {
    String connectionStatus;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      connectionStatus = (await _connectivity.checkConnectivity()).toString();
    } on PlatformException catch (e) {
      print(e.toString());
      connectionStatus = 'Failed to get connectivity.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    setState(() {
      _connectionStatus = connectionStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            datePicked.format(FormatDate.monthYear),
                            style: AppTheme.headline2,
                          ),
                          SizedBox(height: 8),
                          ValueListenableBuilder<int>(
                            valueListenable: totalTask,
                            builder: (context, value, child) => Text(
                              '$value Tasks on ${datePicked.format(FormatDate.dayDate)}',
                              style: AppTheme.text1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              
              
              CalendarTimeline(
                initialDate: datePicked,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2025, 12, 31),
                onDateSelected: (date) async {
                  List<DocumentSnapshot> docs = await _getTaskByDate(date!);

                  setState(() {
                    datePicked = date;
                    documents.value = docs;
                  });
                },
                leftMargin: 20,
                monthColor: Colors.blueGrey,
                dayColor: Colors.teal[200],
                activeDayColor: Colors.white,
                activeBackgroundDayColor: Colors.redAccent[100],
                dotsColor: Color(0xFF333A47),
                locale: 'en_US',
              ),
              
             _showTaskList(),
            ],
          ),
        ),
      ),
      floatingActionButton: DiamondFab(
        onPressed: () {
          _showBottomPanel();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  _topBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Calendar Tasks',
        style: AppTheme.headline3,
        textAlign: TextAlign.center,
      ),
    );
  }

  _showBottomPanel(){
    showModalBottomSheet(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setState){
      return Container(
        height: MediaQuery.of(context).copyWith().size.height * 0.75,
        padding: EdgeInsets.all(20),
        child:Column(
                    children: <Widget>[
                      Text(
                        'Add New Daily Task',
                        style: AppTheme.headline3
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        style: AppTheme.text1.withBlack,
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Type your title here',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your title task';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      Row(
                        children: [
                          Text(
                            'Start Time',
                            style: AppTheme.text3.withBlack,
                          ),
                          SizedBox(width: 120),
                          Text(
                            'End Time',
                            style: AppTheme.text3.withBlack,
                          ),
                        ],
                      ),

                      SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: RippleButton(
                              onTap: (){
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                ).then((value) {
                                  if (value != null) {
                                    setState(() {
                                      _startTime = value;
                                    });
                                  }
                                });
                              },
                              text: _startTime != null
                                  ? _startTime
                                      .format(context).toString()
                                  : 'Start Time',
                              prefixWidget: SvgPicture.asset(
                                  Resources.date,
                                  color: Colors.white,
                                  width: 16),
                              suffixWidget: _startTime != null
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _startTime = TimeOfDay(hour: 0, minute: 0);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: RippleButton(
                              onTap: (){
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                ).then((value) {
                                  if (value != null) {
                                    setState(() {
                                      _endTime = value;
                                    });
                                  }
                                });
                              },
                              text: _endTime != null
                                  ? _endTime
                                      .format(context).toString()
                                  : 'End Time',
                              prefixWidget: SvgPicture.asset(
                                  Resources.date,
                                  color: Colors.white,
                                  width: 16),
                              suffixWidget: _endTime != null
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _endTime = TimeOfDay(hour: 0, minute: 0);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Row(
                        children: [
                          Text(
                            'Start Date',
                            style: AppTheme.text3.withBlack,
                          ),
                          SizedBox(width: 120),
                          Text(
                            'End Date',
                            style: AppTheme.text3.withBlack,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                                child: RippleButton(
                                  onTap: (){
                                    showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    ).then((value) {
                                      if (value != null) {
                                        setState(() {
                                          var date = DateTime(value.year, value.month, value.day);
                                          _startDate = date;
                                        });
                                      }
                                    });
                                  },
                                  text: _startDate != null
                                      ? _startDate
                                          .format(FormatDate.monthDayYear)
                                      : 'Start Date',
                                  prefixWidget: SvgPicture.asset(
                                      Resources.date,
                                      color: Colors.white,
                                      width: 16),
                                  suffixWidget: _startDate != null
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _startDate = DateTime.now();
                                            });
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                          SizedBox(width: 20),
                          Expanded(
                                child: RippleButton(
                                  onTap: (){
                                    showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    ).then((value) {
                                      if (value != null) {
                                        setState(() {                   
                                          _endDate = value;
                                        });
                                      }
                                    });
                                  },
                                  text: _endDate != null
                                      ? _endDate
                                          .format(FormatDate.monthDayYear).toString()
                                      : 'End Date',
                                  prefixWidget: SvgPicture.asset(
                                      Resources.date,
                                      color: Colors.white,
                                      width: 16),
                                  suffixWidget: _endDate != null
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _endDate = DateTime.now();
                                            });
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                        ],
                      ),
                      
                      SizedBox(height: 30),
                      ElevatedButton(                   
                        onPressed: () {
                          addDailyToFirebase();
                          
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent.shade200,
                          foregroundColor: Colors.white,
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),   
                        ),
                        child: Text('Add new task'),
                      ),
                    ]
                  ),
      );
      });
    });
  }
  

  @override
  void dispose() {
    _scaffoldKey.currentState?.dispose();
    _connectivitySubscription.cancel();
    titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
          setState(() {
            _connectionStatus = result.toString();
          });
        });
    initGetTask();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState?.removeCurrentSnackBar();

    _scaffoldKey.currentState?.showSnackBar(new SnackBar(
      content: new Text(value, textAlign: TextAlign.center),
      backgroundColor: Colors.white,
      duration: Duration(seconds: 3),
    ));

  }

  void addDailyToFirebase() async {
    setState(() {
      _saving = true;
    });

    print(_connectionStatus);

    if(_connectionStatus == "ConnectivityResult.none"){
      showInSnackBar("No internet connection currently available");
      setState(() {
        _saving = false;
      });
    } else {

      bool isExist = false;

      QuerySnapshot query =
      await FirebaseFirestore.instance.collection(widget.user.uid).get();

      query.docs.forEach((doc) {
        if (titleController.text.toString() == doc.id) {
          isExist = true;
        }
      });

      

      if (isExist == false && titleController.text.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("Calendar_"+widget.user.uid)
            .doc(titleController.text.toString().trim())
            .set({
          "task": titleController.text.toString().trim(),
          "startTime": _startTime.format(context).toString(),
          "endTime": _endTime.format(context).toString(),
          "startDate": _startDate,
          "endDate": _endDate,
        });

        titleController.clear();

        Navigator.of(context).pop();
      }
      if (isExist == true) {
        showInSnackBar("This list already exists");
        setState(() {
          _saving = false;
        });
      }
      if (titleController.text.isEmpty) {
        showInSnackBar("Please enter a name");
        setState(() {
          _saving = false;
        });
      }
    }
    initGetTask();
  }

  initGetTask() async {
    List<DocumentSnapshot> tempDocs = await _getTaskByDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    documents.value = tempDocs;
  }

  _getTaskByDate(DateTime date) async {
    List<DocumentSnapshot> tempDocs = [];

    QuerySnapshot query = await FirebaseFirestore.instance
        .collection("Calendar_"+widget.user.uid)
        .where("startDate", isLessThanOrEqualTo: date)
        .get();

    if(query.docs.isNotEmpty){
      query.docs.forEach((element) {
        var tempEnd = DateTime.fromMillisecondsSinceEpoch(element['endDate'].seconds * 1000);
        if(tempEnd.isAfter(date) || tempEnd.isAtSameMomentAs(date)){
          tempDocs.add(element);
        }
      });
    }    
    totalTask.value = tempDocs.length;
    return tempDocs;
  }

  _showTaskList() {
    return 
    new Column(
        children: <Widget>[
        SizedBox(
        height: MediaQuery.of(context).size.height - 350,
        child: ValueListenableBuilder(
          valueListenable: documents, 
          builder: (context, List<DocumentSnapshot>docs, _) {
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return Slidable(
                  actionPane: new SlidableDrawerActionPane(),
                  actionExtentRatio: 0.25, 
                  
                  child: ListTile(
                    title: Text(docs[index]['task']),
                    subtitle: Text(docs[index]['startTime'] +
                        " - " +
                        docs[index]['endTime']),
                  ),
                  secondaryActions: <Widget>[
                    new IconSlideAction(
                      caption: 'Delete',
                      color: Colors.red,
                      icon: Icons.delete,
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection("Calendar_"+widget.user.uid)
                            .doc(docs[index].id)
                            .delete();
                        initGetTask();
                        },
                    ),
                  ],
                  );
                
                
              },
            );
        }),
      ),
    ]);
    
  }

}




