library gastro_printing;

import 'dart:convert';
import 'dart:core';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:gastro_printing/src/print.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:queue/queue.dart';

export 'src/print.dart';

abstract class GastroPrinting extends PrintHelper {
  final Map<String, Queue> printerQueue = {};

  Future<String> getCodePage() async {
    final profile = await CapabilityProfile.load();
    return jsonEncode(profile.codePages);
  }

  int getLineMaxLength(int connectionType, String? font) {
    if (connectionType == 0) {
      return (font == null || font == 'Font A') ? 48 : 64;
    } else {
      return (font == null || font == 'Font A') ? 32 : 42;
    }
  }

  Future<PrintResult> printNetworkElements(
    String printerHost,
    int printerPort,
    List<PrintElement> elements, {
    int tryOut = 5,
    Duration timeout = const Duration(seconds: 1),
    DateTime? taskTime,
    String service = '',
    String source = '',
  }) async {
    try {
      PrintResult result;
      if (printerQueue.containsKey(printerHost)) {
        result = await printerQueue[printerHost]!.add(() async {
          logDebug('PRINTER QUEUE',
              'ADD NEW TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] TO $printerHost');
          return await printTaskNetwork(
            printerHost,
            printerPort,
            elements,
            tryOut,
            taskTime: taskTime,
            timeout: timeout,
            service: service,
            source: source,
          );
        });
        logDebug('PRINTER QUEUE',
            'TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] IN $printerHost COMPLETED WITH ${result.toString()}');
      } else {
        logDebug('PRINTER QUEUE', 'ADD NEW QUEUE IS $printerHost');
        printerQueue[printerHost] = Queue(parallel: 1, timeout: const Duration(seconds: 30));
        result = await printerQueue[printerHost]!.add(() async {
          logDebug('PRINTER QUEUE',
              'ADD NEW TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] TO $printerHost');
          return await printTaskNetwork(
            printerHost,
            printerPort,
            elements,
            tryOut,
            taskTime: taskTime,
            timeout: timeout,
          );
        });
        logDebug('PRINTER QUEUE',
            'TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] IN $printerHost COMPLETED WITH ${result.toString()}');
      }
      return result;
    } catch (e) {
      return PrintResult(
        success: false,
        printerHost: printerHost,
        printerStatus: 'PRINT FAILED',
        printerException: 'PRINT FAILED',
        exception: e.toString(),
        taskTime: taskTime,
      );
    }
  }

  Future<bool> printBluetoothElements(String deviceName, String deviceAddress, List<PrintElement> elements) async {
    try {
      BluetoothInfo blueDevice = BluetoothInfo(name: deviceName, macAddress: deviceAddress);
      if (printerQueue.containsKey(deviceAddress)) {
        return await printerQueue[deviceAddress]!.add(() async {
          return await printTaskBluetooth(blueDevice, elements);
        });
      } else {
        printerQueue[deviceAddress] = Queue(
          parallel: 1,
          timeout: const Duration(seconds: 30),
        );
        return await printerQueue[deviceAddress]!.add(() async {
          return await printTaskBluetooth(blueDevice, elements);
        });
      }
    } on Exception {
      return false;
    }
  }

  Future<PrintResult> printTaskNetwork(
    String printerHost,
    int printerPort,
    List<PrintElement> elements,
    int tryOut, {
    Duration timeout = const Duration(seconds: 1),
    DateTime? taskTime,
    String service = '',
    String source = '',
  }) async {
    PrintResult result = await connectNetworkPrinter(
      printerHost,
      printerPort,
      tryOut,
      taskTime: taskTime,
      timeout: timeout,
      service: service,
      source: source,
    );
    if (result.success) {
      try {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        List<int> bytes = bytesGenerator(generator, elements);
        result = await sendBytesToNetworkPrinter(
          printerHost,
          printerPort,
          bytes,
          taskTime: taskTime,
          timeout: timeout,
          sendType: 'PRINT DATA',
          service: service,
          source: source,
        );
        if (result.printerException.contains('20, 0, 64, 15')) {
          result = await connectNetworkPrinter(
            printerHost,
            printerPort,
            1,
            taskTime: taskTime,
            timeout: timeout,
            service: service,
            source: source,
          );
        } else if (result.printerException.contains('28, 0, 12, 15')) {
          result = PrintResult(
            success: false,
            printerHost: printerHost,
            printerStatus: 'OFFLINE',
            printerException: result.printerException,
            exception: 'DUE TO OUT OF PAPER',
            taskTime: taskTime,
          );
        }
      } catch (e) {
        result = PrintResult(
          success: false,
          printerHost: printerHost,
          printerStatus: e.toString(),
          printerException: e.toString(),
          exception: 'DUE TO ${e.toString()}',
          taskTime: taskTime,
        );
      }
    }
    return result;
  }

  Future<bool> printTaskBluetooth(BluetoothInfo bluetoothPrinter, List<PrintElement> elements) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      await PrintBluetoothThermal.disconnect;
    }

    connectionStatus = await PrintBluetoothThermal.connect(macPrinterAddress: bluetoothPrinter.macAddress);
    bool result = false;

    try {
      final profile = await CapabilityProfile.load();
      final printer = Generator(PaperSize.mm58, profile);

      if (connectionStatus) {
        List<int> bytes = bytesGenerator(printer, elements);
        result = await PrintBluetoothThermal.writeBytes(bytes);
        await PrintBluetoothThermal.disconnect;
      }
    } catch (e) {
      logDebug('PRINTING EXCEPTION', e.toString());
    }

    return result;
  }

  Future<PrintResult> connectNetworkPrinter(
    String printerHost,
    int printerPort,
    int tryOut, {
    DateTime? taskTime,
    Duration timeout = const Duration(seconds: 1),
    String service = '',
    String source = '',
  }) async {
    PrintResult pingResult = await ping(
      printerHost,
      printerPort,
      tryOut,
      timeout: timeout,
      taskTime: taskTime,
      service: service,
      source: source,
    );
    if (pingResult.success) {
      final List<int> checkPrinter = <int>[
        int.parse('1D', radix: 16),
        int.parse('61', radix: 16),
        int.parse('0F', radix: 16)
      ];
      int reCheck = 0;
      PrintResult statusResult = await sendBytesToNetworkPrinter(
        printerHost,
        printerPort,
        checkPrinter,
        taskTime: taskTime,
        timeout: Duration(seconds: timeout.inSeconds * 5),
        sendType: 'CHECK PRINTER STATUS $reCheck',
        service: service,
        source: source,
      );
      while (!statusResult.success && reCheck < tryOut) {
        statusResult = await sendBytesToNetworkPrinter(
          printerHost,
          printerPort,
          checkPrinter,
          taskTime: taskTime,
          timeout: Duration(seconds: timeout.inSeconds * 5),
          sendType: 'CHECK PRINTER STATUS $reCheck',
          service: service,
          source: source,
        );
        reCheck++;
      }
      return statusResult;
    } else {
      return pingResult;
    }
  }
}
