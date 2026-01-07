// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter/services.dart';

// class BluetoothSensorPage extends StatefulWidget {
//   const BluetoothSensorPage({super.key});

//   @override
//   State<BluetoothSensorPage> createState() => _BluetoothSensorPageState();
// }

// class _BluetoothSensorPageState extends State<BluetoothSensorPage> {
//   static const MethodChannel iosChannel = MethodChannel("ios_alarm");
//   static const EventChannel btEventChannel = EventChannel(
//     "ios_bluetooth_events",
//   );

//   bool isArmed = false; // Activated or deactivated state
//   bool alarmTriggered = false; // Alarm triggered or not
//   StreamSubscription? btEventSub;

//   @override
//   void initState() {
//     super.initState();

//     // Listen to native Bluetooth events
//     btEventSub = btEventChannel.receiveBroadcastStream().listen((event) async {
//       if (isArmed && !alarmTriggered) {
//         alarmTriggered = true;

//         // Call native iOS to play alarm
//         await iosChannel.invokeMethod("playAlarm");

//         // Show SnackBar for UI feedback
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(event.toString()),
//             backgroundColor: Colors.grey,
//             duration: const Duration(seconds: 3),
//           ),
//         );

//         setState(() {});
//       }
//     });
//   }

//   // Toggle activation/deactivation
//   Future<void> _toggleArmState() async {
//     isArmed = !isArmed;
//     alarmTriggered = false;
//     setState(() {});

//     await iosChannel.invokeMethod("setArmedState", {"armed": isArmed});

//     if (isArmed) {
//       // Start background service to monitor Bluetooth
//       await iosChannel.invokeMethod("startAlarmService");
//     } else {
//       // Stop alarm & background service when deactivated
//       await iosChannel.invokeMethod("stopAlarmService");
//     }
//   }

//   @override
//   void dispose() {
//     btEventSub?.cancel();
//     iosChannel.invokeMethod("stopAlarmService");
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String statusText;
//     if (!isArmed) {
//       statusText = "ALARM DISARMED";
//     } else if (alarmTriggered) {
//       statusText = "ALARM TRIGGERED!";
//     } else {
//       statusText = "ALARM ARMED";
//     }

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("Bluetooth Anti-Theft Alarm"),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: Center(
//         child: Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(25),
//           ),
//           elevation: 10,
//           color: isArmed ? Colors.redAccent : Colors.green,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   isArmed
//                       ? (alarmTriggered ? Icons.warning : Icons.bluetooth)
//                       : Icons.bluetooth_disabled,
//                   color: Colors.white,
//                   size: 70.sp,
//                 ),
//                 SizedBox(height: 15.h),
//                 Text(
//                   statusText,
//                   style: TextStyle(
//                     fontSize: 26.sp,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 25.h),
//                 ElevatedButton(
//                   onPressed: _toggleArmState,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 60.w,
//                       vertical: 18.h,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(35),
//                     ),
//                     elevation: 5,
//                   ),
//                   child: Text(
//                     isArmed ? "DEACTIVATE" : "ACTIVATE",
//                     style: TextStyle(
//                       color: isArmed ? Colors.redAccent : Colors.green,
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothAlarmPage extends StatefulWidget {
  const BluetoothAlarmPage({super.key});

  @override
  State<BluetoothAlarmPage> createState() => _BluetoothAlarmPageState();
}

class _BluetoothAlarmPageState extends State<BluetoothAlarmPage> {
  static const platform = MethodChannel("bluetooth.alarm/channel");

  bool isAlarmActive = false;

  Future<void> activateAlarm() async {
    try {
      final result = await platform.invokeMethod("activateAlarm");
      print(result);
      setState(() => isAlarmActive = true);
    } on PlatformException catch (e) {
      print("Failed to activate alarm: ${e.message}");
    }
  }

  Future<void> deactivateAlarm() async {
    try {
      final result = await platform.invokeMethod("deactivateAlarm");
      print(result);
      setState(() => isAlarmActive = false);
    } on PlatformException catch (e) {
      print("Failed to deactivate alarm: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Alarm")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Bluetooth Alarm is ${isAlarmActive ? "Active" : "Inactive"}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAlarmActive ? deactivateAlarm : activateAlarm,
              child: Text(
                isAlarmActive ? "Deactivate Alarm" : "Activate Alarm",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
