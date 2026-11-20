import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Utility service to activate and bring the Naik Notes desktop window to the
/// foreground after external browser OAuth authentication completes.
class DesktopWindowHelper {
  /// Restores, un-minimizes, and brings the window titled [windowTitle] to the front.
  static void bringToFront([String windowTitle = 'Naik Notes']) {
    try {
      if (Platform.isWindows) {
        _bringToFrontWindows(windowTitle);
      } else if (Platform.isMacOS) {
        _bringToFrontMacOS(windowTitle);
      } else if (Platform.isLinux) {
        _bringToFrontLinux(windowTitle);
      }
    } catch (e) {
      debugPrint('[DesktopWindowHelper] Note bringing window to front: $e');
    }
  }

  static void _bringToFrontWindows(String windowTitle) {
    try {
      final user32 = DynamicLibrary.open('user32.dll');

      final findWindow = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16>, Pointer<Utf16>),
          int Function(Pointer<Utf16>, Pointer<Utf16>)>('FindWindowW');

      final showWindow = user32.lookupFunction<
          Int32 Function(IntPtr, Int32),
          int Function(int, int)>('ShowWindow');

      final setWindowPos = user32.lookupFunction<
          Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
          int Function(int, int, int, int, int, int, int)>('SetWindowPos');

      final setForegroundWindow = user32.lookupFunction<
          Int32 Function(IntPtr),
          int Function(int)>('SetForegroundWindow');

      final bringWindowToTop = user32.lookupFunction<
          Int32 Function(IntPtr),
          int Function(int)>('BringWindowToTop');

      final titlePtr = windowTitle.toNativeUtf16();
      final hwnd = findWindow(nullptr, titlePtr);
      calloc.free(titlePtr);

      if (hwnd != 0) {
        // SW_RESTORE = 9 (Restores if minimized)
        showWindow(hwnd, 9);

        // Temporarily set topmost and then notopmost to ensure it surfaces above
        // the active browser window without remaining stuck permanently on top.
        // HWND_TOPMOST = -1, HWND_NOTOPMOST = -2
        // SWP_NOSIZE = 0x0001, SWP_NOMOVE = 0x0002, SWP_SHOWWINDOW = 0x0040
        setWindowPos(hwnd, -1, 0, 0, 0, 0, 0x0001 | 0x0002);
        setWindowPos(hwnd, -2, 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0040);

        bringWindowToTop(hwnd);
        setForegroundWindow(hwnd);
      }
    } catch (e) {
      debugPrint('[DesktopWindowHelper] Windows Win32 focus note: $e');
    }
  }

  static void _bringToFrontMacOS(String windowTitle) {
    try {
      Process.run('osascript', ['-e', 'tell application "$windowTitle" to activate']);
    } catch (_) {}
  }

  static void _bringToFrontLinux(String windowTitle) {
    try {
      Process.run('wmctrl', ['-a', windowTitle]);
    } catch (_) {}
  }
}
