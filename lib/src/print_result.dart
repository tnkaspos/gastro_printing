class PrintResult {
  final bool success;
  final String printerHost;
  final String printerStatus;
  final String printerException;
  final String exception;

  const PrintResult({
    required this.success,
    required this.printerHost,
    required this.printerStatus,
    required this.printerException,
    required this.exception,
  });

  @override
  String toString() {
    return 'PrintResult(success: $success, printerHost: $printerHost, printerStatus: $printerStatus, printerException: $printerException, exception: $exception)';
  }
}
