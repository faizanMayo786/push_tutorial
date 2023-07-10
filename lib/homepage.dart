import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String token = '';
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    requestPermission();
    getToken();
    initInfo();
    super.initState();
  }

  onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title!),
        content: Text(body!),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Text('Second Screen'),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  initInfo() async {
    // Local Notification Setup
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSIntialize = DarwinInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSIntialize);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        log('${notificationResponse.notificationResponseType}.');

        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            log('${notificationResponse.payload}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Taps')),
                ),
              ),
            );
            break;
          case NotificationResponseType.selectedNotificationAction:
            print(notificationResponse);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Action')),
                ),
              ),
            );
            break;
        }
      },
    );

    // Firebase Message Recieving Code
    FirebaseMessaging.onMessage.listen((event) async {
      print("--------Message-----------");
      print("1 onMessage: ${event.notification!.title}/${event.data}");
      // Preparing to show notification on local device
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        event.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: event.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      final http.Response response =
          await http.get(Uri.parse(event.data['image']));

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'basic',
        'messages',
        importance: Importance.max,
        styleInformation: bigTextStyleInformation,
        priority: Priority.max,
        playSound: true,
        largeIcon: ByteArrayAndroidBitmap.fromBase64String(
            base64Encode(response.bodyBytes)),
        actions: [
          const AndroidNotificationAction('1', 'Done',
              allowGeneratedReplies: true)
        ],
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: const DarwinNotificationDetails(),
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        event.notification!.title,
        event.notification!.body,
        platformChannelSpecifics,
        payload: event.data['body'],
      );
    });
  }

  requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('provisional');
    } else {
      print("failed");
    }
  }

  getToken() async {
    await FirebaseMessaging.instance.getToken().then(
      (value) async {
        log(value!);
        token = value;
        setState(() {});
        // await FirebaseFirestore.instance
        //     .collection('users')
        //     .doc(FirebaseAuth.instance.currentUser!.uid)
        //     .update(
        //   {'token': value},
        // );
      },
    );
  }

  sendNotification(String title, body, to, icon) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization":
              "key=AAAAzpXPElE:APA91bHe6dfcIAXAyb9VlXZLll1n0_RXU0pnmTTBJuTWw9hlXJGkZpckU42_OCHYAAe-ujZfS-Ussa-nW78FCysM6gpU9loqP8gKOdNa5PEmZHwo4-o9OGMcsJcHlQTjwhOsxTNNKhtj",
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            "to": to,
            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "basic",
              'image': icon,
            },
            "data": <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
              'image': icon,
              "url": icon,
            }
          },
        ),
      );
    } on Exception catch (e) {
      print(e);
    }
  }

  _incrementCounter() {
    setState(() {
      _counter++;
    });
    sendNotification(
        'Hi ',
        'increment : $_counter',
        'di8HrFY-RYimn6xLCmc_bk:APA91bFRFAMP8BYC5EanPYfpjL3-dNzT-unw205xeHLzs29oUuN2gffOswRrTxVkl1GTMx_Hy0sXCmInNk6B52v_zL63CPERGwz9-0DVEM9U90XaMWAbHtcIlEUZ0sxp9Y0actzqi7bJ',
        'https://images.unsplash.com/photo-1688607932382-f01b0987c897?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=988&q=80');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'This Device Token:',
            ),
            Text(
              token,
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
