import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:gastro_printing/src/print.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

abstract class PrintHelper {
  String getFitContent(String _input, int _maxLength, {int anchorStyle = 0}) {
    int padLeft = 0;
    int padRight = 0;
    switch (anchorStyle) {

      ///Left Alignment
      case 0:
        {
          padLeft = _maxLength - _input.length > 0 ? _maxLength - _input.length : 0;
        }
        break;

      ///Center Alignment
      case 1:
        {
          padLeft = (_maxLength - _input.length) / 2 as int > 0 ? (_maxLength - _input.length) / 2 as int : 0;
          padRight = _maxLength - _input.length - padLeft;
        }
        break;

      ///Right Alignment
      case 2:
        {
          padRight = _maxLength - _input.length > 0 ? _maxLength - _input.length : 0;
        }
        break;
      default:
        return '';
    }
    String _ret = List.filled(padLeft, ' ').join() + _input + List.filled(padRight, ' ').join();
    return _ret;
  }

  ///Network
  Future<String> sendDataToNetworkPrinter(NetworkPrinter printer, List<PrintElement> elements) async {
    String sendResult = '';
    for (PrintElement e in elements) {
      try {
        switch (e.type) {
          case PrintElementType.char:
            {
              printer.hr(ch: e.columnList[0].text);
            }
            break;
          case PrintElementType.string:
            {
              printer.row(e.columnList);
            }
            break;
          case PrintElementType.command:
            {
              printer.cut();
            }
            break;
        }
      } catch (e) {
        logDebug('SEND DATA TO PRINTER ${e.toString()}');
        sendResult = e.toString();
      }
    }
    return '${sendResult.isEmpty ? 'COMPLETED' : 'FAILED DUE TO $sendResult'}';
  }

  Future<PrintResult> ping(String host, int port, Duration timeout, {int tryOut = 1}) async {
    late Socket _socket;
    bool connected = false;
    String status = 'CONNECTED';
    String exception = 'OK';
    int reCheck = 0;
    while (reCheck < tryOut) {
      try {
        _socket = await Socket.connect(host, port, timeout: timeout);
        _socket.destroy();
        connected = true;
        status = 'CONNECTED';
        exception = 'OK';
      } catch (e) {
        connected = false;
        status = 'DISCONNECTED';
        exception = e.toString();
      }
      reCheck++;
    }
    return PrintResult(
        success: connected, printerHost: host, printerStatus: status, printerException: status, exception: exception);
  }

  ///Network
  Future<PrintResult> testNetworkConnection(String host, int port, List<int> command) async {
    String _secureResponse = '20, 0, 0, 15';
    String _printerResponse = 'TIME OUT';
    late Socket _socket;
    Stopwatch watch = Stopwatch();
    watch.start();
    Completer<String> _completer = Completer<String>();

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));

      /// SENT TO SERVER ************************
      _socket.add(command);

      /// LISTEN TO SERVER ************************
      _socket.listen((data) {
        /// GET FROM SERVER *********************
        _printerResponse = data.toString();
        _socket.close();
        if (!_completer.isCompleted) {
          _completer.complete(_printerResponse);
        }
      }, onError: ((_errorData, StackTrace trace) {
        _printerResponse = _errorData.toString();
        _completer.completeError(_printerResponse);
      }), onDone: () async {
        _socket.destroy();
      }, cancelOnError: false);
      _printerResponse =
          await _completer.future.timeout(Duration(seconds: 5), onTimeout: () => throw Exception('TIME OUT'));
      return PrintResult(
        success: _printerResponse.contains(_secureResponse),
        printerHost: host,
        printerStatus: _printerResponse,
        printerException: _printerResponse,
        exception: 'OK',
      );
    } catch (e) {
      return PrintResult(
        success: _printerResponse.contains(_secureResponse),
        printerHost: host,
        printerStatus: _printerResponse,
        printerException: e.toString(),
        exception: e.toString(),
      );
    }
  }

  ///Bluetooth
  Future<void> sendDataToBluetoothPrinter(Generator printer, List<PrintElement> contents) async {
    List<int> bytes = [];
    for (var e in contents) {
      try {
        switch (e.type) {
          case PrintElementType.char:
            {
              bytes += printer.hr(ch: e.columnList[0].text);
            }
            break;
          case PrintElementType.string:
            {
              bytes += printer.row(e.columnList);
            }
            break;
          case PrintElementType.command:
            {
              bytes += printer.cut();
            }
            break;
        }
      } catch (e) {
        logDebug(e.toString());
      }
    }
    final result = await PrintBluetoothThermal.writeBytes(bytes);
    logDebug('Print test is $result');
  }

  Future<bool> testBluetoothConnection(String mac) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      await PrintBluetoothThermal.disconnect;
    }
    connectionStatus = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    logDebug("state connected $connectionStatus");
    await Future.delayed(const Duration(milliseconds: 200));
    if (connectionStatus) {
      await PrintBluetoothThermal.disconnect;
    } else {}
    return connectionStatus;
  }

  Future<bool> getBluetoothState() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<String> getPairedBluetooth() async {
    List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooth;
    return jsonEncode(pairedDevices);
  }

  Future<bool> connectBluetoothDevice(String macAddress) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  Future<bool> disconnectBluetoothDevice() async {
    if (await PrintBluetoothThermal.connectionStatus) {
      return await PrintBluetoothThermal.disconnect;
    } else {
      return true;
    }
  }

  void logDebug(String msg) {
    debugPrint(msg);
  }

  void logProduct(String msg) {
    print(msg);
  }
}
