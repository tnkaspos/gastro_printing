class PrintResult {
  final bool success;
  final String printerHost;
  final String printerStatus;
  final String printerException;
  final String exception;
  final DateTime? taskTime;

  const PrintResult({
    required this.success,
    required this.printerHost,
    required this.printerStatus,
    required this.printerException,
    required this.exception,
    this.taskTime,
  });

  @override
  String toString() {
    return 'PrintResult(time: ${(taskTime ?? DateTime.now()).millisecondsSinceEpoch}, success: $success, printerHost: $printerHost, printerStatus: $printerStatus, printerException: $printerException, exception: $exception)';
  }
}
