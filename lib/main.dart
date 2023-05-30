import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kiosk_mode/flutter_kiosk_mode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE |
      FlutterWindowManager.FLAG_FULLSCREEN |
      FlutterWindowManager.FLAG_KEEP_SCREEN_ON |
      FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS |
      FlutterWindowManager.FLAG_TRANSLUCENT_STATUS |
      FlutterWindowManager.FLAG_TRANSLUCENT_NAVIGATION);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blue, statusBarIconBrightness: Brightness.light));

  SystemChrome.setEnabledSystemUIOverlays([]);

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> disableNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await flutterLocalNotificationsPlugin.cancelAll();
  }

  await disableNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var timer;

  @override
  void initState() {
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    super.initState();
  }

  final Stream<KioskMode> _currentMode = watchKioskMode();

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder(
          stream: _currentMode,
          builder: (context, snapshot) {
            final mode = snapshot.data;

            if (mode == KioskMode.disabled) {
              startKioskMode();
            }

            if (mode == KioskMode.enabled) {
              timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const WebViewPage()),
                    (Route<dynamic> route) => false);
              });
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Center(child: Text('Please Accept')),
              ],
            );
            // if (mode == KioskMode.disabled) {
            //   SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            // }

            // return const WebViewPage();
          },
        ),
      );
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final Stream<KioskMode> _currentMode = watchKioskMode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                stopKioskMode();
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
              icon: const Icon(Icons.exit_to_app))
        ],
        backgroundColor: Colors.blue,
        title: const Text('Ujian Online'),
      ),
      body: StreamBuilder(
        stream: _currentMode,
        builder: (context, snapshot) {
          final mode = snapshot.data;

          if (mode == KioskMode.disabled) {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }

          return const WebView(
            initialUrl: 'https://flutter.dev',
          );
        },
      ),
    );
  }
}
