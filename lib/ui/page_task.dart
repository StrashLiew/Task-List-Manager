import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_list_manager/model/element.dart';
import 'package:task_list_manager/ui/page_detail.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'page_addlist.dart';
import 'package:task_list_manager/model/custom_value_listenable_builder.dart';
class TaskPage extends StatefulWidget {
  final User user;

  TaskPage({Key? key, required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  int index = 1;
  final ValueNotifier<int> totalTasks = ValueNotifier(0);
  final ValueNotifier<int> completeTasks = ValueNotifier(0);

  double percent(int totalTasks, int completeTasks) {
    try {
      final percentValue = completeTasks / totalTasks;
      if (percentValue.isNaN || percentValue.isInfinite) {
        return 0.0;
      }
      return percentValue;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          _getToolbar(context),
          new Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Task',
                              style: new TextStyle(
                                  fontSize: 30.0, fontWeight: FontWeight.bold, color:Colors.blueAccent),
                            ),
                            Text(
                              'Lists',
                              style: new TextStyle(
                                  fontSize: 28.0, color: Colors.grey),
                            )
                          ],
                        )),
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: new Column(
                  children: <Widget>[
                    new Container(
                      width: 50.0,
                      height: 50.0,
                      decoration: new BoxDecoration(
                          border: new Border.all(color: Colors.blueAccent),
                          borderRadius: BorderRadius.all(Radius.circular(7.0))),
                      child: new IconButton(
                        icon: new Icon(Icons.add),
                        onPressed: _addTaskPressed,
                        iconSize: 30.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text('Add List',
                          style: TextStyle(color: Colors.black45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Container(
              height: 360.0,
              padding: EdgeInsets.only(bottom: 25.0),
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overscroll) {
                  overscroll.disallowIndicator();
                  return true;
                },
                child: new StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(widget.user.uid)
                        .orderBy("date", descending: true)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData)
                        return new Center(
                            child: CircularProgressIndicator(
                          backgroundColor: Colors.blue,
                        ));
                      return new ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(left: 40.0, right: 40.0),
                        scrollDirection: Axis.horizontal,
                        children: getExpenseItems(snapshot),
                      );
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  getExpenseItems(AsyncSnapshot<QuerySnapshot> snapshot) {
    List<ElementTask> listElement = [], listElement2;
    Map<String, List<ElementTask>> userMap = new Map();
    int tempTotal = 0, tempComplete = 0;
    List<String> cardColor = [];
    List<int> cardProgress = [];
    
    if (widget.user.uid.isNotEmpty) {
      cardColor.clear();
      snapshot.data?.docs.map<void>((f) { //snapshot.data.docs.map<List>
        String color = '';
        int nbIsDone = 0;
        Map? data = f.data() as Map?;
        data?.forEach((a, b) {
          if (b.runtimeType == bool) {
            listElement.add(new ElementTask(a, b));
          }
          if (b.runtimeType == String && a == "color") {
            color = b;
          }
        });

        listElement.forEach((i) {
          if (i.isDone) {
            nbIsDone++;
            tempComplete++;
          }
        });
        tempTotal += listElement.length;

        listElement2 = new List<ElementTask>.from(listElement);
        for (int i = 0; i < listElement2.length; i++) {
          if (listElement2.elementAt(i).isDone == false) {
            userMap[f.id] = listElement2;
            cardColor.add(color);
            cardProgress.add(nbIsDone);
            break;
          }
        }
        if (listElement2.length == 0) {
          userMap[f.id] = listElement2;
          cardColor.add(color);
          cardProgress.add(nbIsDone);
        }
        listElement.clear();

      }).toList();
      WidgetsBinding.instance.addPostFrameCallback((_){
        totalTasks.value = tempTotal;
        completeTasks.value = tempComplete;
      });
      

      return new List.generate(userMap.length, (int index) {
        return new GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              new PageRouteBuilder(
                pageBuilder: (_, __, ___) => new DetailPage(
                      user: widget.user,
                      i: index,
                      currentList: userMap,
                      color: cardColor.elementAt(index),
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        new ScaleTransition(
                          scale: new Tween<double>(
                            begin: 1.5,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Interval(
                                0.50,
                                1.00,
                                curve: Curves.linear,
                              ),
                            ),
                          ),
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Interval(
                                  0.00,
                                  0.50,
                                  curve: Curves.linear,
                                ),
                              ),
                            ),
                            child: child,
                          ),
                        ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            color: Color(int.parse(cardColor.elementAt(index))),
            child: new Container(
              width: 220.0,
              //height: 100.0,
              child: Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 3.0),
                      child: Container(
                        child: Text(
                          userMap.keys.elementAt(index),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 5.0),
                            child: Text(
                                " ${cardProgress.elementAt(index)}/${userMap.values.elementAt(index).length} tasks completed",
                                style: TextStyle(fontSize: 13.0, color: Color.fromARGB(221, 0, 0, 0)),
                                textAlign: TextAlign.center,
                              ),
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                // child: Container(
                                //   margin: EdgeInsets.only(left: 50.0),
                                //   color: Colors.white,
                                //   height: 1.5,
                                // ),
                                child: LinearPercentIndicator(
                                  width: 220.0,
                                  lineHeight: 5.0,
                                  percent: percent(userMap.values.elementAt(index).length, cardProgress.elementAt(index)),
                                  backgroundColor: Colors.white.withAlpha(75),
                                  progressColor: Colors.white,
                                  linearStrokeCap: LinearStrokeCap.roundAll,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.only(top: 30.0, left: 15.0, right: 5.0),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 220.0,
                            child: ListView.builder(
                                //physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    userMap.values.elementAt(index).length,
                                itemBuilder: (BuildContext ctxt, int i) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Icon(
                                        userMap.values
                                                .elementAt(index)
                                                .elementAt(i)
                                                .isDone
                                            ? FontAwesomeIcons.checkCircle
                                            : FontAwesomeIcons.circle,
                                        color: userMap.values
                                                .elementAt(index)
                                                .elementAt(i)
                                                .isDone
                                            ? Colors.white70
                                            : Colors.white,
                                        size: 14.0,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                      ),
                                      Flexible(
                                        child: Text(
                                          userMap.values
                                              .elementAt(index)
                                              .elementAt(i)
                                              .name,
                                          style: userMap.values
                                                  .elementAt(index)
                                                  .elementAt(i)
                                                  .isDone
                                              ? TextStyle(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.white70,
                                                  fontSize: 17.0,
                                                )
                                              : TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17.0,
                                                ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _addTaskPressed() async {
    Navigator.of(context).push(
      new PageRouteBuilder(
        pageBuilder: (_, __, ___) => new NewTaskPage(
              user: widget.user,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            new ScaleTransition(
              scale: new Tween<double>(
                begin: 1.5,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Interval(
                    0.50,
                    1.00,
                    curve: Curves.linear,
                  ),
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Interval(
                      0.00,
                      0.50,
                      curve: Curves.linear,
                    ),
                  ),
                ),
                child: child,
              ),
            ),
      ),
    );
    //Navigator.of(context).pushNamed('/new');

  }

  Padding _getToolbar(BuildContext context) {
    return new Padding(
      padding: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
      child:
      ValueListenableBuilder2<int, int>(
        totalTasks,
        completeTasks,
        builder: (context, totalTasks, completeTasks, child){
          return Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 13.0,
                    animation: true,
                    percent: percent(totalTasks, completeTasks),
                    center: Text(
                      "${(percent(totalTasks, completeTasks) * 100).toInt()}%",
                      style: TextStyle(fontSize: 30.0, color: Colors.black54),
                    ),
                    curve: Curves.easeOutExpo,
                    animationDuration: 3000,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.blueAccent,
                    backgroundColor: Colors.blue.withAlpha(75),
                  ),  
              ]),
              Padding(
                padding:  EdgeInsets.only(top:10.0),
                child: Text(
                  "  ${completeTasks}/${totalTasks} tasks completed",
                  style: TextStyle(fontSize: 18.0, color: Colors.black87, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
          );
          
        }

      )
      
    );
  }
}


// new Image(
        //     width: 40.0,
        //     height: 40.0,
        //     fit: BoxFit.cover,
        //     image: new AssetImage('assets/list.png')
        // ), 