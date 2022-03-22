class PrintResult {
  final bool success;
  final String printerHost;
  final String printerStatus;
  final String exception;

  const PrintResult({
    required this.success,
    required this.printerHost,
    required this.printerStatus,
    required this.exception,
  });

  @override
  String toString() {
    return 'PrintResult(success: $success, printerHost: $printerHost, printerStatus: $printerStatus, exception: $exception)';
  }
}
