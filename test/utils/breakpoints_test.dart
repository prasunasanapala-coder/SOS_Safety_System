import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/utils/breakpoints.dart';

void main() {
  test('fromWidth maps widths to screen sizes at 600 and 1024', () {
    expect(Breakpoints.fromWidth(320), ScreenSize.mobile);
    expect(Breakpoints.fromWidth(599.9), ScreenSize.mobile);
    expect(Breakpoints.fromWidth(600), ScreenSize.tablet);
    expect(Breakpoints.fromWidth(1023), ScreenSize.tablet);
    expect(Breakpoints.fromWidth(1024), ScreenSize.desktop);
    expect(Breakpoints.fromWidth(1920), ScreenSize.desktop);
  });

  test('page padding grows with screen size', () {
    expect(Breakpoints.pagePadding(ScreenSize.mobile), 16);
    expect(Breakpoints.pagePadding(ScreenSize.tablet), 24);
    expect(Breakpoints.pagePadding(ScreenSize.desktop), 32);
  });
}