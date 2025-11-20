import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/tostring/tostring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToStringRuleTest);
  });
}

@reflectiveTest
class ToStringRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ToStringRule();
    super.setUp();
  }

  void test_missing_toString() async {
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

  void test_correct_toString_no_diagnostics() async {
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

  void test_generic_class_missing_toString_reports_lint() async {
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

  void test_generic_class_with_toString_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  final T value;

  Box({required this.value});

  @override
  String toString() => 'Box(value: $value)';
}
''');
  }
}
