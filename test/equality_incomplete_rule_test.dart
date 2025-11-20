import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/equality_incomplete/equality_incomplete.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualityIncompleteRuleTest);
  });
}

@reflectiveTest
class EqualityIncompleteRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = EqualityIncompleteRule();
    super.setUp();
  }

  void test_incomplete_equality_missing_field_reports_lint() async {
    await assertDiagnostics(
      r'''
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Person &&
            other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);
}
''',
      [lint(134, 2)],
    );
  }

  void test_incomplete_hashCode_missing_field_reports_lint() async {
    await assertDiagnostics(
      r'''
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
  int get hashCode => Object.hashAll([name]);
}
''',
      [lint(308, 8)],
    );
  }

  void test_complete_equality_and_hashCode_all_fields_no_diagnostics() async {
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
}
