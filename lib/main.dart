import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String _timeString; //화면의 타이머
  Timer timer; //타이머 객체
  SharedPreferences timeHouse; //시간저장소
  var startTime;
  var endTime;
  var diffTime;
  var checkTimer = true;
  int diff = 0;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initSettings = new InitializationSettings(android, iOS);

    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);

    this.timeCheck();
  }

  timeCheck() async {
    this.timeHouse = await SharedPreferences.getInstance();
    if (this.timeHouse.getString('timeHouse') == null) {
      return;
    }

    _timeString = _formatDateTime(DateTime.now());
    runTimer();

    var startTime = timeHouse.getString('timeHouse');
    var endTime = timeHouse.getString('endTime');
    if (endTime == null) {
      return;
    }

    var startTimeBody = jsonDecode(startTime);
    var endTimeBody = jsonDecode(endTime);

    if (endTimeBody['date'] ==
        DateFormat('yyyy-MM-dd').format(DateTime.now()).toString()) {
      setState(() {
        this.startTime = startTimeBody['time'];
        this.endTime = endTimeBody['time'];
      });
    }
  }

  void runTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (this.checkTimer == false || this.diff == null || this.diff < 1) {
        t.cancel();
        reset();
      } else {
        _getTime();
      }
    });
  }

  /*
   * 남은시간 출력
   */
  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime now) {
    if (this.timeHouse == null || checkTimer == false) {
      return '';
    }

    var endTime = jsonDecode(this.timeHouse.getString('endTime'));
    if (endTime == null || endTime == '') {
      return '';
    }

    var splitEndDay = endTime['date'].toString().split('-');

    var month = now.month.toString();
    if (now.month.toString().length == 1) {
      month = '0' + month.toString();
    }

    var nowStr;

    if (now.day.toString().length == 1) {
      nowStr = '0' + now.day.toString();
    }

    if (splitEndDay[0] != now.year.toString() ||
        splitEndDay[1] != month ||
        splitEndDay[2] != nowStr.toString()) {
      return '';
    }

    var splitEndTime = endTime['time'].toString().split(':');

    var endTimeData = DateTime(
        int.parse(splitEndDay[0]),
        int.parse(splitEndDay[1]),
        int.parse(splitEndDay[2]),
        int.parse(splitEndTime[0]),
        int.parse(splitEndTime[1]),
        0);

    this.diff = endTimeData.difference(now).inMilliseconds;
    this.diffTime = DateFormat('HH:mm:ss')
        .format(DateTime.fromMillisecondsSinceEpoch(this.diff, isUtc: true));
    return this.diffTime;
  }

  /*
   * 출근시작버튼
   */
  void _startWork(selfHour, selfMin) {
    var selfTime = null;
    this.checkTimer = true;
    DateTime now = DateTime.now();
    var hour = now.hour.toString();
    var min = now.minute.toString();

    var time;

    if (selfHour != null && selfMin != null) {
      hour = selfHour;
      min = selfMin;
      selfTime = new DateTime(
          now.year, now.month, now.day, int.parse(hour), int.parse(min));
    }

    if (min.toString().length == 1 || min.toString() == '0') {
      min = '0' + min;
    }

    if (selfHour != null && selfMin != null) {
      if (selfHour.length < 2) {
        selfHour = '0' + selfHour;
      }
      time = selfHour + ':' + selfMin;
    } else {
      time = DateFormat('HH:mm').format(now);
    }
    var today = DateFormat('yyyy-MM-dd').format(now);
    var startTimeBody = {'date': today, 'time': time};
    var endTimeBody = {
      'date': today,
      'time': (int.parse(hour) + 9).toString() + ':' + min
    };

    var timeHouse = this.timeHouse.getString('timeHouse');

    if (timeHouse == null) {
      this.timeHouse.setString('timeHouse', jsonEncode(startTimeBody));
      this.timeHouse.setString('endTime', jsonEncode(endTimeBody));
      setState(() {
        this.startTime = startTimeBody['time'];
        this.endTime = endTimeBody['time'];
      });

      _timeString = _formatDateTime(DateTime.now());

      runTimer();
      showNotificationAtTime(selfTime);
      startDialog();
    }
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('OK'),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                )
              ],
            ));
  }

  /*
   * 알림수신 dialog
   */
  Future onSelectNotification(String payload) async {
    showCupertinoDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text('퇴근시간 알림'),
              content: new Text('$payload'),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('OK'),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('WorkTimeSystem', textAlign: TextAlign.center),
        backgroundColor: Color.fromRGBO(0, 88, 142, 1.0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              child: _timeString == null
                  ? Image.asset(
                      'lib/shoes.png',
                      scale: 1.0,
                    )
                  : Image.asset(
                      'lib/clock.png',
                      scale: 1.0,
                    ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                _timeString == null ? '출근중' : '퇴근까지',
                style: TextStyle(
                    fontSize: 33, color: Color.fromRGBO(109, 109, 109, 1.0)),
              ),
            ),
            Container(
                margin: EdgeInsets.only(top: 10, bottom: 20),
                child: _timeString == null
                    ? Text(
                        '00:00:00',
                        style: TextStyle(
                          fontSize: 65,
                          color: Color.fromRGBO(6, 86, 136, 0.3),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        _timeString,
                        style: TextStyle(
                          fontSize: 65,
                          color: Color.fromRGBO(6, 86, 136, 1.0),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      )),
            Container(
              width: 150,
              height: 55,
              margin: EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  startTime == null
                      ? Text(
                          '출근시간 : 00:00',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromRGBO(109, 109, 109, 1.0),
                          ),
                        )
                      : Text(
                          '오늘출근 : ' + startTime,
                          style: TextStyle(fontSize: 16),
                        ),
                  endTime == null
                      ? Text(
                          '퇴근시간 : 00:00',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromRGBO(109, 109, 109, 1.0),
                          ),
                        )
                      : Text(
                          '오늘퇴근 : ' + endTime,
                          style: TextStyle(fontSize: 16),
                        ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 30, bottom: 10),
              width: 252,
              height: 45,
              child: FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  color: Color.fromRGBO(8, 67, 123, 1.0),
                  child: _timeString == null
                      ? Text(
                          'Arrive',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        )
                      : Text(
                          'Reset',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                  onPressed: () => _timeString == null
                      ? _startWork(null, null)
                      : resetDialog()),
            ),
            _timeString == null
                ? FlatButton(
                    child: Text(
                      '직접 입력',
                      style: TextStyle(
                          color: Color.fromRGBO(8, 67, 123, 1.0), fontSize: 16),
                    ),
                    onPressed: showDatePicker,
                  )
                : FlatButton()
          ],
        ),
      ),
    );
  }

  resetDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text('초기화'),
              content: Text('출근데이터를 초기화 하시겠습니까?'),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('확인'),
                  onPressed: () async {
                    Navigator.pop(context);
                    reset();
                  },
                )
              ],
            ));
  }

  startDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text('출근 시작'),
              content: Text('퇴근 30분, 10분 전에 퇴근알람이 울립니다.'),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('확인'),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                )
              ],
            ));
  }

  reset() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    
    try {
      setState(() {
        this.timeHouse.clear();
        this.startTime = null;
        this.endTime = null;
        this.diffTime = null;
        this._timeString = null;
        this.checkTimer = false;
        this.diff = 0;
      });
    } catch (e) {
      debugPrint(e);
    }
  }

  showNotificationAtTime(selfTime) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, iOS);
    DateTime scheduledNotificationDateTime;
    DateTime endWorkTime;

    if (selfTime != null) {
      scheduledNotificationDateTime =
          selfTime.add(new Duration(seconds: 30600));
      endWorkTime = selfTime.add(new Duration(seconds: 31800));
    } else {
      scheduledNotificationDateTime =
          new DateTime.now().add(new Duration(seconds: 30600));
      endWorkTime = new DateTime.now().add(new Duration(seconds: 31800));
    }

    await flutterLocalNotificationsPlugin.cancelAll();

    await flutterLocalNotificationsPlugin.schedule(
        0, 'WorkTimeSystem', '퇴근시간 알림', scheduledNotificationDateTime, platform,
        payload: '퇴근 30분 전입니다.');

    await flutterLocalNotificationsPlugin.schedule(
        1, 'WorkTimeSystem', '퇴근 10분전 알림', endWorkTime, platform,
        payload: '퇴근 10분 전입니다.');
  }

  /*
   * 직접 입력 - 출근 시간 직접 설정하는 dialog
   */
  showDatePicker() async {
    TimeOfDay time = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: 09, minute: 00));
    if (time != null) {
      var selfMin;
      if (time.minute.toString().length == 1) {
        selfMin = '0' + time.minute.toString();
      } else {
        selfMin = time.minute;
      }
      _startWork(time.hour.toString(), selfMin);
    }
  }
}
