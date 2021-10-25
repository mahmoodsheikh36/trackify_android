import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/api/api.dart';

class HistoryWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HistoryWidgetState();
}

class HistoryWidgetState extends State<HistoryWidget> {
  final ItemScrollController _scrollController = ItemScrollController();
  DateTime _firstPlayDateTime;
  int currentMonthIdx = -1;
  Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = () async {
      _firstPlayDateTime = await apiClient.getFirstPlayDateTime();
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        }
        DateTime lastPlayDateTime = apiClient.data.lastPlayDateTime();
        List<DateTime> months = [];
        DateTime firstMonth = DateTime(_firstPlayDateTime.year, _firstPlayDateTime.month);
        for (DateTime m = firstMonth; m.isBefore(lastPlayDateTime); m = DateTime(m.year, m.month + 1)) {
          months.add(m);
        }
        if (currentMonthIdx == -1) {
          currentMonthIdx = months.length - 1;
        }
        DateTime month = months[currentMonthIdx];
        return Column(
          children: [
            SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: mainBlack),
                    tooltip: "previous",
                    onPressed: () {
                      setState(() {
                          if (currentMonthIdx > 0) {
                            currentMonthIdx = currentMonthIdx - 1;
                          }
                      });
                    },
                  ),
                  Text(DateFormat('MMMM y').format(month)),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: mainBlack),
                    tooltip: "next",
                    onPressed: () {
                      setState(() {
                          if (currentMonthIdx < months.length - 1) {
                            currentMonthIdx = currentMonthIdx + 1;
                          }
                      });
                    },
                  ),
                ]
              )
            ),
            Expanded(
              child: FutureBuilder<APIData>(
                future: () async {
                  return await apiClient.getData(month, DateTime(month.year, month.month + 1));
                }(),
                builder: (BuildContext context, AsyncSnapshot<APIData> snapshot) {
                  if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
                    APIData data = snapshot.data;
                    List<Play> sortedPlays = data.sortedPlays();
                    List<DateTime> days = [];
                    List<dynamic> rowData = [];
                    for (Play play in sortedPlays) {
                      DateTime playTime = play.startDateTime();
                      DateTime day = DateTime(playTime.year, playTime.month, playTime.day);
                      if (!days.contains(day)) {
                        days.add(day);
                        rowData.add(day);
                      }
                      rowData.add(play);
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: ScrollablePositionedList.builder(
                            itemScrollController: _scrollController,
                            itemCount: rowData.length,
                            itemBuilder: (BuildContext context, int index) {
                              print('${index}/${rowData.length}');
                              dynamic data = rowData[index];
                              if (data is DateTime) {
                                return Container(
                                  padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                                  child: Text("${rowData[index].day}/${rowData[index].month}"),
                                );
                              } else if (data is Play) {
                                return Container(
                                  padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                                  child: HorizontalMusicEntryWidget.fromTrack(rowData[index].track),
                                );
                              }
                            }
                          ),
                        ),
                        Container(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Reference', style: TextStyle(color: mainRed)),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: days.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    DateTime day = days[index];
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        child: Center(
                                          child: Text("${day.day}/${day.month}"),
                                        ),
                                        onTap: () {
                                          int idx = 0;
                                          for (dynamic data in rowData) {
                                            if (data is DateTime) {
                                              if (data.isAtSameMomentAs(day)) {
                                                _scrollController.scrollTo(
                                                  index: idx,
                                                  duration: Duration(seconds: 1),
                                                  curve: Curves.easeInOutCubic
                                                );
                                                break;
                                              }
                                            }
                                            idx++;
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        );
      }
    );
  }
}
