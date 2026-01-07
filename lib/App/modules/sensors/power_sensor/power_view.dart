import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class ChargerAlarmPage extends StatefulWidget {
  const ChargerAlarmPage({super.key});

  @override
  State<ChargerAlarmPage> createState() => _ChargerAlarmPageState();
}

class _ChargerAlarmPageState extends State<ChargerAlarmPage> {
  static const MethodChannel _chargerChannel = MethodChannel(
    'charger.alarm/channel',
  );

  bool isArmed = false;
  bool isAlarmPlaying = false; // reflects current charger state

  // Toggle arm/disarm
  Future<void> toggleAlarm() async {
    try {
      if (isArmed) {
        await _chargerChannel.invokeMethod('disarmAlarm');
        setState(() {
          isArmed = false;
          isAlarmPlaying = false;
        });
      } else {
        await _chargerChannel.invokeMethod('armAlarm');
        setState(() {
          isArmed = true;
          // alarm will trigger automatically if charger unplugged
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Error toggling charger alarm: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Charger Alarm"),
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
              color: isArmed ? Colors.redAccent : Colors.green,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      isArmed
                          ? Icons.battery_alert
                          : Icons.battery_charging_full,
                      color: Colors.white,
                      size: 60.sp,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      isArmed ? "Alarm Armed" : "Alarm Disarmed",
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
              "Get alerted immediately if your phone charger is unplugged, even in background.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
