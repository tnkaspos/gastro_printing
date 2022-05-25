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
              logDebug('BYTE EXCEPTION', e.toString());
            }
          }
          break;
        case PrintElementType.string:
          {
            try {
              bytes += printer.row(e.columnList);
            } catch (e) {
              logDebug('BYTE EXCEPTION', e.toString());
            }
          }
          break;
        case PrintElementType.command:
          {
            try {
              bytes += printer.cut();
            } catch (e) {
              logDebug('BYTE EXCEPTION', e.toString());
            }
          }
          break;
      }
    }
    bytes += checkPrinter;
    return bytes;
  }

  ///Network
  Future<PrintResult> ping(
    String host,
    int port,
    int tryOut, {
    DateTime? taskTime,
    Duration timeout = const Duration(seconds: 1),
    String service = '',
    String source = '',
  }) async {
    late Socket _socket;
    bool connected = false;
    String status = 'CONNECTED';
    String exception = 'OK';
    int reCheck = 0;
    while (reCheck < tryOut && !connected) {
      try {
        _socket = await Socket.connect(host, port, timeout: timeout);
        _socket.destroy();
        connected = true;
        status = 'CONNECTED';
        exception = 'OK';
        logDebug(
          'PRINTER RESPONSE',
          'FOR PING TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] $host RETURNED $status',
        );
      } catch (e) {
        connected = false;
        status = 'DISCONNECTED';
        exception = e.toString();
        logDebug(
          'PRINTER RESPONSE',
          'FOR PING TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] $host RETURNED $status',
        );
      }
      reCheck++;
    }
    return PrintResult(
      success: connected,
      printerHost: host,
      printerStatus: status,
      printerException: status,
      exception: exception,
      taskTime: taskTime,
    );
  }

  Future<PrintResult> sendBytesToNetworkPrinter(
    String host,
    int port,
    List<int> command, {
    Duration timeout = const Duration(seconds: 5),
    DateTime? taskTime,
    String sendType = 'UNKNOWN',
    String service = '',
    String source = '',
  }) async {
    String _secureResponse = '20, 0, 0, 15';
    String _printerResponse = '';
    late Socket _socket;
    Completer<String> _completer = Completer<String>();

    try {
      _socket = await Socket.connect(host, port, timeout: timeout);

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
      _printerResponse = await _completer.future.timeout(
        Duration(seconds: timeout.inSeconds * 5),
        onTimeout: () {
          throw Exception('TIME OUT');
        },
      );
      logDebug('PRINTER RESPONSE',
          'FOR $sendType TASK [${(taskTime ?? DateTime.now()).millisecondsSinceEpoch} - $service - $source] $host RETURNED $_printerResponse');
      return PrintResult(
        success: _printerResponse.contains(_secureResponse),
        printerHost: host,
        printerStatus: _printerResponse.contains(_secureResponse) ? 'ONLINE' : _printerResponse,
        printerException: _printerResponse.contains(_secureResponse) ? '' : _printerResponse,
        exception: 'OK',
        taskTime: taskTime,
      );
    } catch (e) {
      return PrintResult(
        success: _printerResponse.contains(_secureResponse),
        printerHost: host,
        printerStatus: _printerResponse,
        printerException: e.toString(),
        exception: e.toString(),
        taskTime: taskTime,
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
    List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooths;
    return jsonEncode(pairedDevices);
  }

  void logDebug(String header, String content) {
    printWrapped('PRINTING LOG: [$header] $content');
  }

  void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }

  void logProduct(String header, String content) {
    printWrapped('PRINTING LOG: [$header] $content');
  }
}
