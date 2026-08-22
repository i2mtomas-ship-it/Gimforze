import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una semana comienza en lunes', () {
    final date = DateTime(2026, 8, 10); // lunes
    expect(date.weekday, 1);
  });

  test('el volumen semanal se puede expresar en toneladas', () {
    const volume = 12500.0;
    expect((volume / 1000).toStringAsFixed(0), '13');
  });
}
