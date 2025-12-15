import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// Code generation helpers (kept in one place to avoid duplication)

/// Builds a toString() override snippet for the given class and fields.
String buildToStringSnippet(String className, Iterable<String> fieldNames) {
  final fieldsText = fieldNames.isNotEmpty
      ? fieldNames.map((f) => '$f: \$$f').join(', ')
      : '';

  return '''

  @override
  String toString() {
    return '$className{$fieldsText}';
  }
''';
}

/// Builds equality operator and hashCode getter snippet.
String buildEqualityAndHashCodeSnippet(
  String className,
  List<
    ({
      String name,
      String type,
      bool isNamed,
      bool isNullable,
      bool isCollection,
    })
  >
  fields, {
  required DartFileEditBuilder builder,
}) {
  final equalitySnippet = buildEqualitySnippet(
    className,
    fields,
    builder: builder,
  );
  final hashCodeSnippet = buildHashCodeSnippet(fields, builder: builder);

  return '$equalitySnippet\n\n$hashCodeSnippet';
}

/// Builds equality operator snippet.
String buildEqualitySnippet(
  String className,
  List<
    ({
      String name,
      String type,
      bool isNamed,
      bool isNullable,
      bool isCollection,
    })
  >
  fields, {
  required DartFileEditBuilder builder,
}) {
  if (fields.any((f) => f.isCollection)) {
    builder.importLibrary(Uri.parse('package:collection/collection.dart'));
  }

  final equalityFields = fields
      .map((f) {
        if (f.isCollection) {
          return 'const DeepCollectionEquality().equals(${f.name}, other.${f.name})';
        }
        return '${f.name} == other.${f.name}';
      })
      .join(' && ');
  final equalityCheck = fields.isNotEmpty ? ' && $equalityFields' : '';
  return '''

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $className$equalityCheck;''';
}

/// Builds hashCode getter snippet.
String buildHashCodeSnippet(
  List<
    ({
      String name,
      String type,
      bool isNamed,
      bool isNullable,
      bool isCollection,
    })
  >
  fields, {
  DartFileEditBuilder? builder,
}) {
  if (builder != null && fields.any((f) => f.isCollection)) {
    builder.importLibrary(Uri.parse('package:collection/collection.dart'));
  }

  final hashList = fields
      .map((f) {
        if (f.isCollection) {
          return 'const DeepCollectionEquality().hash(${f.name})';
        }
        return f.name;
      })
      .join(', ');

  return '''

  @override
  int get hashCode => Object.hash($hashList);''';
}

/// Builds a copyWith(...) snippet for the class based on the best constructor.
/// Returns null if no suitable constructor/fields found.
String? buildCopyWithSnippet(ClassDeclaration classDecl) {
  final className = getClassName(classDecl);
  final constructorFields = getClassFields(classDecl, constructorOnly: true);
  if (constructorFields.isEmpty) {
    return null;
  }

  final positionalFields = constructorFields.where((f) => !f.isNamed).toList();
  final namedFields = constructorFields.where((f) => f.isNamed).toList();

  final params = constructorFields
      .map((f) {
        if (f.isNullable) {
          return '({${f.type}? value})? ${f.name}';
        } else {
          return '({${f.type} value})? ${f.name}';
        }
      })
      .join(', ');

  final positionalArgs = positionalFields
      .map((f) => '${f.name} == null ? this.${f.name} : ${f.name}.value')
      .join(', ');

  final namedArgs = namedFields
      .map(
        (f) =>
            '${f.name}: ${f.name} == null ? this.${f.name} : ${f.name}.value',
      )
      .join(', ');

  final constructorArgs = [
    if (positionalArgs.isNotEmpty) positionalArgs,
    if (namedArgs.isNotEmpty) namedArgs,
  ].join(', ');

  return '''

  $className copyWith({$params}) {
    return $className($constructorArgs);
  }
''';
}

/// Gets the equality (==) method from a class, if it exists
MethodDeclaration? getEqualityMethod(ClassDeclaration node) {
  try {
    return node.members.whereType<MethodDeclaration>().firstWhere((member) {
      final name = member.declaredFragment?.element.name ?? member.name.lexeme;

      return name == '==' && member.isOperator;
    });
  } catch (_) {
    return null;
  }
}

/// Gets the hashCode method from a class, if it exists
MethodDeclaration? getHashCodeMethod(ClassDeclaration node) {
  try {
    return node.members.whereType<MethodDeclaration>().firstWhere((member) {
      final name = member.declaredFragment?.element.name ?? member.name.lexeme;

      return name == 'hashCode' && member.isGetter;
    });
  } catch (_) {
    return null;
  }
}

/// Gets the toString method from a class, if it exists
MethodDeclaration? getToStringMethod(ClassDeclaration node) {
  try {
    return node.members.whereType<MethodDeclaration>().firstWhere((member) {
      final name = member.declaredFragment?.element.name ?? member.name.lexeme;

      return name == 'toString' && !member.isStatic;
    });
  } catch (_) {
    return null;
  }
}

/// Gets the copyWith method from a class, if it exists
MethodDeclaration? getCopyWithMethod(ClassDeclaration node) {
  try {
    return node.members.whereType<MethodDeclaration>().firstWhere((member) {
      final name = member.declaredFragment?.element.name ?? member.name.lexeme;

      return name == 'copyWith' && !member.isStatic;
    });
  } catch (_) {
    return null;
  }
}

/// Gets the best constructor for copyWith generation
/// Returns null if no suitable constructor is found
ConstructorDeclaration? getBestConstructorForCopyWith(ClassDeclaration node) {
  final constructors = node.members
      .whereType<ConstructorDeclaration>()
      .toList();

  if (constructors.isEmpty) {
    return null; // Cannot generate copyWith!
  }

  // Priority 1: Unnamed constructor with named parameters
  final unnamedWithNamedParams = constructors.firstWhereOrNull((c) {
    final name = c.name?.lexeme;
    final hasNamedParams = c.parameters.parameters.any((p) => p.isNamed);
    return name == null && hasNamedParams;
  });

  if (unnamedWithNamedParams != null) {
    return unnamedWithNamedParams;
  }

  // Priority 2: Any unnamed constructor
  final unnamed = constructors.firstWhereOrNull((c) => c.name?.lexeme == null);

  if (unnamed != null) {
    return unnamed;
  }

  // Priority 3: Named constructor with most named parameters
  final bestNamed = constructors.reduce((a, b) {
    final aNamedCount = a.parameters.parameters.where((p) => p.isNamed).length;
    final bNamedCount = b.parameters.parameters.where((p) => p.isNamed).length;
    return aNamedCount >= bNamedCount ? a : b;
  });

  return bestNamed;
}

/// Validates if constructor is suitable for copyWith generation
bool isConstructorSuitableForCopyWith(ConstructorDeclaration constructor) {
  final element = constructor.declaredFragment?.element;

  // Cannot use factory constructors for copyWith
  if (element?.isFactory ?? false) {
    return false;
  }

  // Need at least some parameters
  if (constructor.parameters.parameters.isEmpty) {
    return false;
  }

  return true;
}

/// Gets the fields of a class as a list of records containing
/// name, type, isNamed, and isNullable.
/// If constructorOnly is true, only fields present in the best constructor are returned.
List<
  ({String name, String type, bool isNamed, bool isNullable, bool isCollection})
>
getClassFields(ClassDeclaration node, {bool constructorOnly = false}) {
  final constructor = getBestConstructorForCopyWith(node);

  // Build parameter map from constructor (if exists)
  final parameterMap = <String, bool>{};
  if (constructor != null) {
    for (final param in constructor.parameters.parameters) {
      final name = param.declaredFragment?.name ?? param.name!.lexeme;
      parameterMap[name] = param.isNamed;
    }
  }

  // If constructorOnly is true, we need a suitable constructor
  if (constructorOnly) {
    if (constructor == null) {
      return [];
    }

    if (!isConstructorSuitableForCopyWith(constructor)) {
      return [];
    }
  }

  final allFields = node.members
      .whereType<FieldDeclaration>()
      .where((f) => !f.isStatic)
      .expand(
        (fieldDecl) => fieldDecl.fields.variables.map((v) {
          final name = v.declaredFragment?.name ?? v.name.lexeme;
          final declaredElement = v.declaredFragment?.element;
          final type = declaredElement?.type.getDisplayString() ?? 'dynamic';
          final isNullable =
              declaredElement?.type.nullabilitySuffix ==
              NullabilitySuffix.question;
          final isCollection =
              declaredElement?.type.isDartCoreList == true ||
              declaredElement?.type.isDartCoreIterable == true ||
              declaredElement?.type.isDartCoreSet == true ||
              declaredElement?.type.isDartCoreMap == true;
          final isNamed = parameterMap[name] ?? false;

          return (
            name: name,
            type: type,
            isNamed: isNamed,
            isNullable: isNullable,
            isCollection: isCollection,
          );
        }),
      )
      .toList();

  // If constructorOnly is true, filter to only include constructor parameters
  if (constructorOnly) {
    return allFields
        .where((field) => parameterMap.containsKey(field.name))
        .toList();
  }

  return allFields;
}

/// Gets the name of the class
String getClassName(ClassDeclaration node) {
  return node.declaredFragment?.name ?? node.name.lexeme;
}

Set<String> getFieldsInFunctionBody(MethodDeclaration method) {
  final fields = <String>{};
  final visitor = _FieldExtractor(fields);
  method.body.accept(visitor);
  return fields;
}

/// Gets the parameter names from a copyWith method
Set<String> getCopyWithParameters(MethodDeclaration method) {
  final params = <String>{};
  final paramList = method.parameters?.parameters;
  if (paramList != null) {
    for (final param in paramList) {
      if (param is DefaultFormalParameter) {
        params.add(param.name!.lexeme);
      } else if (param is SimpleFormalParameter) {
        params.add(param.name!.lexeme);
      }
    }
  }
  return params;
}

/// Returns the set of fields that are missing from an existing copyWith method
Set<String> getMissingFieldsInCopyWith(
  ClassDeclaration classDecl,
  MethodDeclaration copyWithMethod,
) {
  final classFieldNames = getClassFields(
    classDecl,
    constructorOnly: true,
  ).map((field) => field.name);

  final copyWithParams = getCopyWithParameters(copyWithMethod);

  return classFieldNames
      .where((field) => !copyWithParams.contains(field))
      .toSet();
}

/// Returns the set of fields that are missing from an existing toString method
Set<String> getMissingFieldsInToString(
  ClassDeclaration classDecl,
  MethodDeclaration toStringMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final toStringFieldNames = getFieldsInFunctionBody(toStringMethod);

  return classFieldNames
      .where((field) => !toStringFieldNames.contains(field))
      .toSet();
}

/// Returns the set of fields that are missing from an existing equality operator
Set<String> getMissingFieldsInEquality(
  ClassDeclaration classDecl,
  MethodDeclaration equalityMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final equalityFieldNames = getFieldsInFunctionBody(equalityMethod);

  return classFieldNames
      .where((field) => !equalityFieldNames.contains(field))
      .toSet();
}

/// Returns the set of fields that are missing from an existing hashCode getter
Set<String> getMissingFieldsInHashCode(
  ClassDeclaration classDecl,
  MethodDeclaration hashCodeMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final hashCodeFieldNames = getFieldsInFunctionBody(hashCodeMethod);

  return classFieldNames
      .where((field) => !hashCodeFieldNames.contains(field))
      .toSet();
}

class _FieldExtractor extends RecursiveAstVisitor<void> {
  final Set<String> fields;

  _FieldExtractor(this.fields);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is PropertyAccessorElement &&
        (element.kind == ElementKind.FIELD ||
            element.kind == ElementKind.GETTER)) {
      fields.add(node.name);
    }
    super.visitSimpleIdentifier(node);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
