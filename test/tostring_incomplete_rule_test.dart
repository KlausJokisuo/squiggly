// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/tostring_incomplete/tostring_incomplete.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncompleteToStringRuleTest);
  });
}

@reflectiveTest
class IncompleteToStringRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = IncompleteClassToStringRule();
    super.setUp();
  }

  void test_incomplete_toString_missing_field_reports_lint() async {
    await assertDiagnostics(
      r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  @override
  String toString() => 'Person(name: $name)';
}
''',
      [lint(127, 8)],
    );
  }

  void test_complete_toString_all_fields_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  @override
  String toString() => 'Person(name: $name, age: $age)';
}
''');
  }
}
