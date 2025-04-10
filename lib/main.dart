import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
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
  String? notificationText;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
    messaging = FirebaseMessaging.instance;

    messaging.subscribeToTopic("messaging");//subscribe to topic

    messaging.getToken().then((value) { //getting token value 
      print(value);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) { //listen for event
      print("message received"); 
      print(event.notification!.body); //print the notification body 
      print(event.data.values); 
      print("message type ${event.messageType}");
      bool isImportant = event.data['type'] == 'important';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Notification"),
            content: Text(event.notification!.body!),
            // ignore: unrelated_type_equality_checks
            backgroundColor: isImportant?Colors.red:Colors.blue,
            actions: [
              TextButton(
                child: Text("action 1"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleAction('action_1');
                },
              ),
               TextButton(
                child: Text("action 2"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleAction('action_2');
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



  void _handleAction(String action) {
    // Implement your action handling here
    Fluttertoast.showToast(msg: "Action $action clicked!");
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
      ),
      body: Center(child: Text("Messaging Tutorial")),
    );
  }
}
