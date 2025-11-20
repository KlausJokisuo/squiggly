import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:squiggly/copywith/copywith.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CopyWithRuleTest);
  });
}

@reflectiveTest
class CopyWithRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CopyWithRule();
    super.setUp();
  }

  void test_missing_copyWith() async {
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

  void test_has_copyWith_no_diagnostics() async {
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

  void test_multiple_classes_reports_each_missing_copyWith() async {
    await assertDiagnostics(
      r'''
class Person {
  final String name;

  Person({required this.name});
}

class Car {
  final String model;

  Car({required this.model});
}
''',
      [lint(6, 6), lint(78, 3)],
    );
  }

  void test_generic_class_missing_copyWith_reports_lint() async {
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

  void test_generic_class_with_copyWith_no_diagnostics() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  final T value;

  Box({required this.value});

  Box<T> copyWith({T? value}) {
    return Box(value: value ?? this.value);
  }
}
''');
  }
}
