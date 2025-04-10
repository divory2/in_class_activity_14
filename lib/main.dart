import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firebase_options.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification?.body ?? "No Body"}');
  await saveNotification(
    message.notification?.title ?? "No Title",
    message.notification?.body ?? "No Body",
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
    messaging = FirebaseMessaging.instance;

    messaging.subscribeToTopic("messaging");

    FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
      final title = event.notification?.title ?? "No Title";
      final body = event.notification?.body ?? "No Body";

      print("message received: $title");
      print(event.data);
      await saveNotification(title, body);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            backgroundColor: event.data['importance'] == "high"
                ? Colors.red
                : Colors.blue,
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });
  }

  void _getFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $token");
      if (token != null) {
        Fluttertoast.showToast(msg: "FCM Token: $token");
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () async {
              final notifications = await getNotificationHistory();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NotificationHistoryScreen(notifications),
              ));
            },
          )
        ],
      ),
      body: Center(child: Text("Messaging Tutorial")),
    );
  }
}

// ✅ Save notification locally
// ✅ Save notification locally
Future<void> saveNotification(String title, String body) async {
  final prefs = await SharedPreferences.getInstance();
  final String? existingData = prefs.getString('notification_history');

  List<Map<String, String>> notifications = [];

  if (existingData != null) {
    // Decode and cast the data properly
    var decodedData = json.decode(existingData) as List;
    notifications = decodedData.map((item) => Map<String, String>.from(item)).toList();
  }

  notifications.add({
    'title': title,
    'body': body,
    'timestamp': DateTime.now().toIso8601String(),
  });

  // Print notifications to debug
  print("Saved Notifications: ${json.encode(notifications)}");

  await prefs.setString('notification_history', json.encode(notifications));
}

// ✅ Load saved notifications
Future<List<Map<String, String>>> getNotificationHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final String? data = prefs.getString('notification_history');

  if (data != null) {
    // Decode and cast the data properly
    var decodedData = json.decode(data) as List;
    return decodedData.map((item) => Map<String, String>.from(item)).toList();
  }

  return [];
}

// ✅ Simple screen to show notification history
class NotificationHistoryScreen extends StatelessWidget {
  final List<Map<String, String>> notifications;

  NotificationHistoryScreen(this.notifications);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification History")),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification['title'] ?? "No Title"),
            subtitle: Text(notification['body'] ?? "No Body"),
            trailing: Text(
              DateTime.parse(notification['timestamp']!).toLocal().toString(),
              style: TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
