import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WifiAlarmPage extends StatefulWidget {
  const WifiAlarmPage({super.key});

  @override
  State<WifiAlarmPage> createState() => _WifiAlarmPageState();
}

class _WifiAlarmPageState extends State<WifiAlarmPage> {
  static const methodChannel = MethodChannel("wifi.alarm/channel");

  bool isConnected =
      false; // you can optionally remove this, since we won't get live status from native
  bool isAlarmPlaying = false;
  bool isArmed = false;

  Future<void> toggleAlarm() async {
    try {
      if (isArmed) {
        await methodChannel.invokeMethod("deactivateAlarm");
      } else {
        await methodChannel.invokeMethod("activateAlarm");
      }

      setState(() {
        isArmed = !isArmed;
        isAlarmPlaying = isArmed; // show alarm active when armed
      });
    } on PlatformException catch (e) {
      print("Error calling native method: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wi-Fi Sensor Alarm"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              elevation: 6,
              color: isAlarmPlaying ? Colors.redAccent : Colors.green,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 60.sp,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      isConnected ? "Wi-Fi Connected" : "Wi-Fi Disconnected",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: toggleAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isArmed
                            ? Colors.redAccent
                            : Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 50.w,
                          vertical: 15.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: Text(
                        isArmed ? "DE-ACTIVATE" : "ACTIVATE",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.h),
            const Text(
              "Save your phone from pickpockets as soon as someone tries to steal it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
