import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squiggly/utils.dart';
import 'package:test/test.dart';

class MockDartFileEditBuilder extends Mock implements DartFileEditBuilder {}

class FakeUri extends Fake implements Uri {}

MethodDeclaration _firstMethod(ClassDeclaration clazz, String name) {
  return clazz.members.whereType<MethodDeclaration>().firstWhere(
    (m) => m.name.lexeme == name,
  );
}

/// Shared temp directory and context collection for faster test execution.
late final Directory _tempDir;
late final AnalysisContextCollection _collection;
int _fileCounter = 0;

final mockBuilder = MockDartFileEditBuilder();

/// Resolves code and returns the first class declaration with full semantic info.
Future<ClassDeclaration> _resolveFirstClass(String code) async {
  final tempFile = File('${_tempDir.path}/test_${_fileCounter++}.dart');
  tempFile.writeAsStringSync(code);
  final context = _collection.contextFor(tempFile.path);
  final result = await context.currentSession.getResolvedUnit(tempFile.path);
  if (result is ResolvedUnitResult) {
    return result.unit.declarations.whereType<ClassDeclaration>().first;
  }
  throw StateError('Failed to resolve code');
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
    _tempDir = Directory.systemTemp.createTempSync('squiggly_test_');
    _collection = AnalysisContextCollection(includedPaths: [_tempDir.path]);
  });

  tearDownAll(() {
    _tempDir.deleteSync(recursive: true);
  });

  group('snippet builders', () {
    test('buildToStringSnippet no fields', () {
      final snippet = buildToStringSnippet('User', const []);
      expect(snippet, """

  @override
  String toString() {
    return 'User{}';
  }
""");
    });

    test('buildToStringSnippet with fields', () {
      final snippet = buildToStringSnippet('User', ['name', 'age']);
      expect(snippet, """

  @override
  String toString() {
    return 'User{name: \$name, age: \$age}';
  }
""");
    });

    test('buildEqualitySnippet no fields', () {
      final snippet = buildEqualitySnippet(
        'User',
        const [],
        builder: mockBuilder,
      );
      expect(snippet, """

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User;""");
    });

    test('buildEqualitySnippet with fields', () {
      final fields = [
        (
          name: 'name',
          type: 'String',
          isNamed: false,
          isNullable: false,
          isCollection: false,
        ),
        (
          name: 'age',
          type: 'int',
          isNamed: false,
          isNullable: false,
          isCollection: false,
        ),
      ];
      final snippet = buildEqualitySnippet(
        'User',
        fields,
        builder: mockBuilder,
      );
      expect(snippet, """

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && name == other.name && age == other.age;""");
    });

    test('buildHashCodeSnippet fields', () {
      final fields = [
        (
          name: 'name',
          type: 'String',
          isNamed: false,
          isNullable: false,
          isCollection: false,
        ),
        (
          name: 'age',
          type: 'int',
          isNamed: false,
          isNullable: false,
          isCollection: false,
        ),
      ];
      final snippet = buildHashCodeSnippet(fields);
      expect(snippet, """

  @override
  int get hashCode => Object.hash(name, age);""");
    });

    test('buildEqualityAndHashCodeSnippet combines both', () {
      final fields = [
        (
          name: 'name',
          type: 'String',
          isNamed: false,
          isNullable: false,
          isCollection: false,
        ),
      ];
      final snippet = buildEqualityAndHashCodeSnippet(
        'User',
        fields,
        builder: mockBuilder,
      );
      expect(snippet, """

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && name == other.name;


  @override
  int get hashCode => Object.hash(name);""");
    });

    test('buildEqualityAndHashCodeSnippet with collection fields', () {
      when(() => mockBuilder.importLibrary(any())).thenReturn('meow');

      final fields = [
        (
          name: 'tags',
          type: 'List<String>',
          isNamed: false,
          isNullable: false,
          isCollection: true,
        ),
      ];
      final snippet = buildEqualityAndHashCodeSnippet(
        'User',
        fields,
        builder: mockBuilder,
      );
      expect(
        snippet,
        '\n'
        '  @override\n'
        '  bool operator ==(Object other) =>\n'
        '      identical(this, other) ||\n'
        '      other is User && const DeepCollectionEquality().equals(tags, other.tags);\n'
        '\n'
        '\n'
        '  @override\n'
        '  int get hashCode => Object.hash(const DeepCollectionEquality().hash(tags));',
      );
    });
  });

  group('buildCopyWithSnippet', () {
    test('returns null when no suitable constructor', () async {
      const code = 'class A { }';
      final clazz = await _resolveFirstClass(code);
      expect(buildCopyWithSnippet(clazz), isNull);
    });

    test(
      'generates copyWith for unnamed constructor with named params',
      () async {
        const code = '''
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}
''';

        final clazz = await _resolveFirstClass(code);
        final snippet = buildCopyWithSnippet(clazz)!;

        expect(snippet, contains('User copyWith'));
        expect(snippet, contains('name == null ? this.name : name.value'));
        expect(snippet, contains('age == null ? this.age : age.value'));
      },
    );

    test('respects nullability of fields', () async {
      const code = '''
class User {
  final String? name;
  final int age;

  User({this.name, required this.age});
}
''';

      final clazz = await _resolveFirstClass(code);
      final snippet = buildCopyWithSnippet(clazz)!;

      expect(snippet, contains('copyWith'));
      expect(snippet, contains('name == null ? this.name : name.value'));
      expect(snippet, contains('age == null ? this.age : age.value'));
    });

    test('generates copyWith with generic types', () async {
      const code = '''
class User {
  final List<Animal> pets;
  User({required this.pets});
}
class Animal {}
''';

      final clazz = await _resolveFirstClass(code);
      final snippet = buildCopyWithSnippet(clazz)!;

      expect(snippet, contains('({List<Animal> value})? pets'));
    });
  });

  group('class helpers', () {
    test('getClassName', () async {
      const code = 'class User {}';
      final clazz = await _resolveFirstClass(code);
      expect(getClassName(clazz), 'User');
    });

    test('getClassFields constructorOnly false', () async {
      const code = '''
class User {
  final String name;
  int? age;
  static int counter = 0;

  User(this.name, {this.age});
}
''';

      final clazz = await _resolveFirstClass(code);
      final fields = getClassFields(clazz);

      expect(fields.length, 2);
      final nameField = fields.firstWhere((f) => f.name == 'name');
      final ageField = fields.firstWhere((f) => f.name == 'age');

      expect(nameField.type, isNotEmpty);
      expect(ageField.type, isNotEmpty);
      expect(ageField.isNullable, isTrue);
    });

    test('getClassFields constructorOnly true', () async {
      const code = '''
class User {
  final String name;
  final int age;
  final String nickname;

  User(this.name, this.age);
}
''';

      final clazz = await _resolveFirstClass(code);
      final fields = getClassFields(clazz, constructorOnly: true);

      expect(fields.map((f) => f.name), containsAll(['name', 'age']));
      expect(fields.map((f) => f.name), isNot(contains('nickname')));
    });
  });

  group('existing methods detection', () {
    test('finds equality, hashCode, toString, copyWith', () async {
      const code = '''
class User {
  final String name;

  User(this.name);

  @override
  bool operator ==(Object other) => other is User && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'User{name: \$name}';

  User copyWith({({String value})? name}) => User(name == null ? this.name : name.value);
}
''';

      final clazz = await _resolveFirstClass(code);

      expect(getEqualityMethod(clazz), isNotNull);
      expect(getHashCodeMethod(clazz), isNotNull);
      expect(getToStringMethod(clazz), isNotNull);
      expect(getCopyWithMethod(clazz), isNotNull);
    });
  });

  group('copyWith analysis helpers', () {
    test('getCopyWithParameters and getMissingFieldsInCopyWith', () async {
      const code = '''
class User {
  final String name;
  final int age;

  User(this.name, this.age);

  User copyWith({({String value})? name}) {
    return User(name == null ? this.name : name.value, age);
  }
}
''';

      final clazz = await _resolveFirstClass(code);
      final copyWith = getCopyWithMethod(clazz)!;

      final params = getCopyWithParameters(copyWith);
      expect(params, {'name'});

      final missing = getMissingFieldsInCopyWith(clazz, copyWith);
      expect(missing, {'age'});
    });

    test('getMissingFieldsInToString/equality/hashCode', () async {
      const code = '''
class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  String toString() => 'User{name: \$name}';

  @override
  bool operator ==(Object other) => other is User && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
''';

      final clazz = await _resolveFirstClass(code);
      final toStringMethod = _firstMethod(clazz, 'toString');
      final equalityMethod = getEqualityMethod(clazz)!;
      final hashCodeMethod = getHashCodeMethod(clazz)!;

      final missingToString = getMissingFieldsInToString(clazz, toStringMethod);
      final missingEquality = getMissingFieldsInEquality(clazz, equalityMethod);
      final missingHashCode = getMissingFieldsInHashCode(clazz, hashCodeMethod);

      expect(missingToString, equals({'age'}));
      expect(missingEquality, equals({'age'}));
      expect(missingHashCode, equals({'age'}));
    });
  });
}
