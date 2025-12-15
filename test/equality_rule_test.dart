// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/equality/equality.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualityRuleTest);
  });
}

@reflectiveTest
class EqualityRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = EqualityRule();
    super.setUp();
  }

  void test_missing_equality_and_hashCode() async {
    await assertDiagnostics(
      r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});
}
''',
      [lint(6, 6)],
    );
  }

  void test_correct_equality_and_hashCode_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Person &&
            other.name == name &&
            other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);
}
''');
  }

  void test_generic_class_missing_equality_and_hashCode_reports_lint() async {
    await assertDiagnostics(
      r'''
class Box<T> {
  final T value;

  Box({required this.value});
}
''',
      [lint(6, 3)],
    );
  }

  void test_generic_class_with_equality_and_hashCode_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  final T value;

  Box({required this.value});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Box<T> &&
            other.value == value;
  }

  @override
  int get hashCode => Object.hashAll([value]);
}
''');
  }
}
