import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  List<int> bytesGenerator(Generator printer, List<PrintElement> elements) {
    List<int> bytes = [];
    final List<int> checkPrinter = <int>[
      int.parse('1D', radix: 16),
      int.parse('61', radix: 16),
      int.parse('0F', radix: 16),
    ];
    for (PrintElement e in elements) {
      switch (e.type) {
        case PrintElementType.char:
          {
            try {
              bytes += printer.hr(ch: e.columnList[0].text);
            } catch (e) {
              logDebug(e.toString());
            }
          }
          break;
        case PrintElementType.string:
          {
            try {
              bytes += printer.row(e.columnList);
            } catch (e) {
              logDebug(e.toString());
            }
          }
          break;
        case PrintElementType.command:
          {
            try {
              bytes += printer.cut();
            } catch (e) {
              logDebug(e.toString());
            }
          }
          break;
      }
    }
    bytes += checkPrinter;
    return bytes;
  }

  ///Network
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

  Future<PrintResult> sendBytesToNetworkPrinter(String host, int port, List<int> command) async {
    String _secureResponse = '20, 0, 0, 15';
    String _printerResponse = 'TIME OUT';
    late Socket _socket;
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
      _printerResponse = await _completer.future.timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('TIME OUT');
      });
      logDebug('PRINTER RESPONSE: $host RETURNED $_printerResponse');
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
