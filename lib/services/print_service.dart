import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'dart:io';

class PrintService {
  /// Fetches the list of printers on Windows via PowerShell
  static Future<List<String>> getPrinters() async {
    try {
      final result = await Process.run(
        'powershell', 
        ['-command', 'Get-WmiObject -Class Win32_Printer | Select-Object -ExpandProperty Name']
      );
      
      if (result.exitCode == 0) {
        final String output = result.stdout;
        return output
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error fetching printers: $e');
    }
    return [];
  }

  /// Sends raw ESC/POS byte data to a specific printer name in Windows.
  static bool printRawBytes(String printerName, List<int> dataToPrint) {
    bool isSuccess = false;

    using((Arena alloc) {
      final pPrinterName = printerName.toNativeUtf16(allocator: alloc);
      final phPrinter = alloc<HANDLE>();

      // Open Printer
      var fSuccess = OpenPrinter(pPrinterName, phPrinter, nullptr);
      if (fSuccess == 0) {
        final error = GetLastError();
        print('OpenPrint error, status: $fSuccess, error: $error');
        return;
      }

      // Start Document
      final pDocInfo = alloc<DOC_INFO_1>()
        ..ref.pDocName = 'Restaurant Receipt'.toNativeUtf16(allocator: alloc)
        ..ref.pDatatype = 'RAW'.toNativeUtf16(allocator: alloc)
        ..ref.pOutputFile = nullptr;

      fSuccess = StartDocPrinter(
          phPrinter.value,
          1, // Version of the structure to which pDocInfo points.
          pDocInfo);
      
      if (fSuccess == 0) {
        final error = GetLastError();
        ClosePrinter(phPrinter.value);
        print('StartDocPrinter error, status: $fSuccess, error: $error');
        return;
      }

      // Start Page
      fSuccess = StartPagePrinter(phPrinter.value);
      if (fSuccess == 0) {
        EndDocPrinter(phPrinter.value);
        ClosePrinter(phPrinter.value);
        return;
      }

      // Write Printer
      final cWritten = alloc<DWORD>();
      final data = alloc<Uint8>(dataToPrint.length);
      for (var i = 0; i < dataToPrint.length; i++) {
        data[i] = dataToPrint[i];
      }

      final writeResult = WritePrinter(
          phPrinter.value, data.cast<Void>(), dataToPrint.length, cWritten);
      
      if (dataToPrint.length != cWritten.value) {
        final error = GetLastError();
        print('WritePrinter error, status: $writeResult, error: $error');
      } else {
        isSuccess = true;
      }

      // End Page
      EndPagePrinter(phPrinter.value);

      // End Job
      EndDocPrinter(phPrinter.value);
      ClosePrinter(phPrinter.value);
    });

    return isSuccess;
  }
}
