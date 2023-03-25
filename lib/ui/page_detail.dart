import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_list_manager/model/element.dart';
import 'package:task_list_manager/utils/diamond_fab.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DetailPage extends StatefulWidget {
  final User user;
  final int i;
  final Map<String, List<ElementTask>> currentList;
  final String color;

  DetailPage({Key? key, required this.user, required this.i, required this.currentList, required this.color})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  TextEditingController itemController = new TextEditingController();

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
      //key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: new Stack(
        children: <Widget>[
          _getToolbar(context),
          Container(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (overscroll) {
                overscroll.disallowGlow();
                return true;
              },
              child: new StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(widget.user.uid)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData)
                      return new Center(
                          child: CircularProgressIndicator(
                        backgroundColor: currentColor,
                      ));
                    return new Container(
                      child: getExpenseItems(snapshot),
                    );
                  }),
            ),
          ),
        ],
      ),
      floatingActionButton: DiamondFab(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: <Widget>[
                    Expanded(
                      child: new TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(
                                    color: currentColor)),
                            labelText: "Item",
                            hintText: "Item",
                            contentPadding: EdgeInsets.only(
                                left: 16.0,
                                top: 20.0,
                                right: 16.0,
                                bottom: 5.0)),
                        controller: itemController,
                        style: TextStyle(
                          fontSize: 22.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  ButtonTheme(
                    //minWidth: double.infinity,
                    child: ElevatedButton(                   
                      onPressed: () {
                        if (itemController.text.isNotEmpty &&
                            !widget.currentList.values
                                .contains(itemController.text.toString())) {
                          FirebaseFirestore.instance
                              .collection(widget.user.uid)
                              .doc(
                                  widget.currentList.keys.elementAt(widget.i))
                              .update(
                                  {itemController.text.toString(): false});

                          itemController.clear();
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentColor,
                        foregroundColor: Colors.white,
                        elevation: 3.0,
                        // shape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.circular(32.0),
                        // ),
                      // color: currentColor,
                      // textColor: const Color(0xffffffff),
                      ),
                      child: Text('Add'),
                    ),
                  )
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: currentColor,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  getExpenseItems(AsyncSnapshot<QuerySnapshot> snapshot) {
    List<ElementTask> listElement = [];
    int nbIsDone = 0;

    if (widget.user.uid.isNotEmpty) {
      snapshot.data?.docs.map<void>((f) {  //snapshot.data.docs.map<Column>
        if (f.id == widget.currentList.keys.elementAt(widget.i)) {
          Map? data = f.data() as Map?;
          data?.forEach((a, b) {
            if (b.runtimeType == bool) {
              listElement.add(new ElementTask(a, b));
            }
          });
        }
      }).toList();

      listElement.forEach((i) {
        if (i.isDone) {
          nbIsDone++;
        }
      });

      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 90.0),
            child: new Column(
              children: <Widget>[
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 13.0,
                  animation: true,
                  percent: percent(listElement.length, nbIsDone),
                  center: Text(
                    "${(percent(listElement.length, nbIsDone) * 100).toInt()}%",
                    style: TextStyle(fontSize: 30.0, color: Colors.black54),
                  ),
                  curve: Curves.easeOutExpo,
                  animationDuration: 3000,
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: currentColor,
                  backgroundColor: currentColor.withAlpha(75),
                ),
                Padding(
                  padding: EdgeInsets.only( left: 50.0, right: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          widget.currentList.keys.elementAt(widget.i),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 35.0),
                        ),
                      ),
                    ],
                  ),  
                ),
              
                Padding(
                  padding: EdgeInsets.only(top: 5.0, left: 50.0),
                  child: Row(
                    children: <Widget>[
                      new Text(
                        nbIsDone.toString() +
                            " of " +
                            listElement.length.toString() +
                            " tasks",
                        style: TextStyle(fontSize: 18.0, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.only(left: 50.0),
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Column(
                    children: <Widget>[
                      Container(color: Color(0xFFFCFCFC),child:
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 350,
                        child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 68.0),
                            physics: const BouncingScrollPhysics(),
                            itemCount: listElement.length,
                            itemBuilder: (BuildContext ctxt, int i) {
                              return new Slidable(
                                actionPane: new SlidableDrawerActionPane(),
                                actionExtentRatio: 0.25,
                                child: GestureDetector(
                                  onTap: () {
                                    FirebaseFirestore.instance
                                        .collection(widget.user.uid)
                                        .doc(widget.currentList.keys
                                            .elementAt(widget.i))
                                        .update({
                                      listElement.elementAt(i).name:
                                          !listElement.elementAt(i).isDone
                                    });
                                  },
                                  child: Container(
                                    height: 50.0,
                                    color: listElement.elementAt(i).isDone
                                        ? Color(0xFFF0F0F0)
                                        : Color(0xFFFCFCFC),
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 50.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Icon(
                                            listElement.elementAt(i).isDone
                                                ? FontAwesomeIcons.checkSquare
                                                : FontAwesomeIcons.square,
                                            color: listElement
                                                    .elementAt(i)
                                                    .isDone
                                                ? currentColor
                                                : Colors.black,
                                            size: 20.0,
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(left: 30.0),
                                          ),
                                          Flexible(
                                            child: Text(
                                              listElement.elementAt(i).name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: listElement
                                                      .elementAt(i)
                                                      .isDone
                                                  ? TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color: currentColor,
                                                      fontSize: 27.0,
                                                    )
                                                  : TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 27.0,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                secondaryActions: <Widget>[
                                  new IconSlideAction(
                                    caption: 'Delete',
                                    color: Colors.red,
                                    icon: Icons.delete,
                                    onTap: () {
                                        FirebaseFirestore.instance
                                            .collection(widget.user.uid)
                                            .doc(widget.currentList.keys
                                            .elementAt(widget.i))
                                            .update({
                                          listElement.elementAt(i).name:
                                          ""
                                        });
                                    },
                                  ),
                                ],
                              );
                            }),
                      ),),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    pickerColor = Color(int.parse(widget.color));
    currentColor = Color(int.parse(widget.color));
  }

  late Color pickerColor;
  late Color currentColor;

  late ValueChanged<Color> onColorChanged;

  changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  Padding _getToolbar(BuildContext context) {
    return new Padding(
      padding: EdgeInsets.only(top: 25.0, left: 20.0, right: 12.0),
      child:
          new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            // new Image(
            //     width: 35.0,
            //     height: 35.0,
            //     fit: BoxFit.cover,
            //     image: new AssetImage('assets/list.png')
            // ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return new AlertDialog(
                      title: Text("Delete: " + widget.currentList.keys.elementAt(widget.i).toString()),
                      content: Text(
                          "Are you sure you want to delete this list?", style: TextStyle(fontWeight: FontWeight.w400),),
                      actions: <Widget>[
                        ButtonTheme(
                          //minWidth: double.infinity,
                          child: ElevatedButton(                        
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('No'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentColor,
                              foregroundColor: Colors.white,
                              elevation: 3.0,
                              // shape: RoundedRectangleBorder(
                              //   borderRadius:
                              //   BorderRadius.circular(32.0),
                              // ),
                            ),
                          ),
                        ),
                        ButtonTheme(
                          //minWidth: double.infinity,
                          child: ElevatedButton(                                      
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection(widget.user.uid)
                                  .doc(widget.currentList.keys
                                  .elementAt(widget.i))
                                  .delete();
                              Navigator.pop(context);
                              Navigator.of(context).pop();
                            },
                            child: Text('YES'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentColor,
                              foregroundColor: Colors.white,
                              elevation: 3.0,
                              // shape: RoundedRectangleBorder(
                              //   borderRadius:
                              //   BorderRadius.circular(32.0),
                              // ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ); 
              },
            child: Icon(
                  FontAwesomeIcons.trash,
                  size: 35.0,
                  color: currentColor,
                ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 3.0,
                backgroundColor: currentColor,
                foregroundColor: const Color(0xffffffff),
              ),
              onPressed: () {
                pickerColor = currentColor;
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pick a color!'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: changeColor,
                          //enableLabel: true,
                          colorPickerWidth: 500.0,
                          pickerAreaHeightPercent: 0.7,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Got it'),
                          onPressed: () {

                            FirebaseFirestore.instance
                                .collection(widget.user.uid)
                                .doc(
                                widget.currentList.keys.elementAt(widget.i))
                                .update(
                                {"color": pickerColor.value.toString()});

                            setState(
                                    () => currentColor = pickerColor);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Color'),
            ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: new Icon(
            Icons.close,
            size: 40.0,
            color: currentColor,
          ),
        ),
      ]),
    );
  }
}