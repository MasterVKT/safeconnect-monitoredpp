import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Simple test to verify test framework works', () {
    expect(1 + 1, equals(2));
  });
  
  test('String operations', () {
    expect('hello'.toUpperCase(), equals('HELLO'));
  });
}