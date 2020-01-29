import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class TimeList extends StatefulWidget {
  @override
  _TimeListState createState() {
    return _TimeListState();
  }
}

class _TimeListState extends State<TimeList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('타이틀'),
      ),
      body: FutureBuilder(
          future: _getTimeHouse(),
          builder: (context, timeHouse) {
            if (timeHouse.data == null) {
              print('null');
              return Container();
            }
            print(timeHouse.data);
            // print(timeHouse.data);
            return ListView.builder(
              itemCount: timeHouse.data.length,
              itemBuilder: (context, index) {
                return Text('===>' +
                    timeHouse.data['date'] +
                    ':::' +
                    timeHouse.data['time']);
              },
            );
          }),
    );
  }

  Future<List> _getTimeHouse() async {
    SharedPreferences timeHouse = await SharedPreferences.getInstance();
    var data = [timeHouse.getString('timeHouse')];
    List list = data;
    // List list = json.decode(data);
    return list;
  }
}
