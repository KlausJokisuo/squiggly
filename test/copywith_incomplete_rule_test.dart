// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/copywith_incomplete/copywith_incomplete.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CopyWithIncompleteRuleTest);
  });
}

@reflectiveTest
class CopyWithIncompleteRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CopyWithIncompleteRule();
    super.setUp();
  }

  void test_incomplete_copyWith_missing_field_reports_lint() async {
    await assertDiagnostics(
      r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  Person copyWith({String? name}) {
    return Person(
      name: name ?? this.name,
      age: age,
    );
  }
}
''',
      [lint(115, 8)],
    );
  }

  void test_complete_copyWith_all_fields_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  Person copyWith({String? name, int? age}) {
    return Person(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
''');
  }
}
