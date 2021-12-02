library gastro_printing;

import 'dart:convert';
import 'dart:core';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:queue/queue.dart';

import 'src/print.dart';

export 'src/print.dart';

abstract class GastroPrinting extends PrintHelper {
  final printingQueue = Queue(
    parallel: 1,
    timeout: const Duration(seconds: 3600),
  );

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

  Future<bool> printNetworkElements(String printerHost, int printerPort, List<PrintElement> elements) async {
    try {
      return await printingQueue.add(() async {
        return await printTaskNetwork(printerHost, printerPort, elements);
      });
    } on Exception {
      return false;
    }
  }

  Future<bool> printBluetoothElements(String deviceName, String deviceAddress, List<PrintElement> elements) async {
    try {
      BluetoothInfo blueDevice = BluetoothInfo(name: deviceName, macAddress: deviceAddress);
      return await printingQueue.add(() => printTaskBluetooth(blueDevice, elements));
    } on Exception {
      return false;
    }
  }

  Future<bool> printTaskNetwork(String printerHost, int printerPort, List<PrintElement> elements) async {
    bool printable = await connectNetworkPrinter(printerHost, printerPort, tryOut: 5);
    if (printable) {
      try {
        int reConnect = 0;
        final profile = await CapabilityProfile.load();
        final printer = NetworkPrinter(PaperSize.mm80, profile);

        PosPrintResult res = await printer.connect(printerHost, port: printerPort, timeout: const Duration(seconds: 2));

        while (res != PosPrintResult.success && reConnect < 5) {
          res = await printer.connect(printerHost, port: printerPort, timeout: const Duration(seconds: 1));
          reConnect++;
        }

        if (res == PosPrintResult.success) {
          sendDataToNetworkPrinter(printer, elements);
          printer.disconnect();
          return printable;
        } else {
          return !printable;
        }
      } catch (e) {
        logger(e.toString());
        return !printable;
      }
    } else {
      return printable;
    }
  }

  Future<bool> printTaskBluetooth(BluetoothInfo bluetoothPrinter, List<PrintElement> elements) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      await PrintBluetoothThermal.disconnect;
    }

    connectionStatus = await PrintBluetoothThermal.connect(macPrinterAddress: bluetoothPrinter.macAddress);

    try {
      final profile = await CapabilityProfile.load();
      final printer = Generator(PaperSize.mm58, profile);

      if (connectionStatus) {
        await sendDataToBluetoothPrinter(printer, elements);
        await PrintBluetoothThermal.disconnect;
      }
    } catch (e) {
      logger(e.toString());
    }

    return true;
  }

  Future<bool> connectNetworkPrinter(String printerHost, int printerPort, {int tryOut = 1}) async {
    bool printable = false;
    if (await ping(printerHost, printerPort, Duration(seconds: 2))) {
      final List<int> checkPrinter = <int>[
        int.parse('1D', radix: 16),
        int.parse('61', radix: 16),
        int.parse('0F', radix: 16)
      ];
      int reCheck = 0;
      while (!printable && reCheck < tryOut) {
        printable = await testNetworkConnection(printerHost, printerPort, checkPrinter);
        reCheck++;
      }
    } else {
      printable = false;
    }
    return printable;
  }
}
