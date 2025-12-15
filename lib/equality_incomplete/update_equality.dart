import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:squiggly/utils.dart';

class UpdateEquality extends ResolvedCorrectionProducer {
  UpdateEquality({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => FixKind(
    'dart.assist.update_class_equality',
    DartFixKindPriority.standard,
    'Update equality and hashCode to include all fields',
  );

  @override
  AssistKind get assistKind => AssistKind(
    'dart.assist.update_class_equality',
    DartFixKindPriority.standard,
    'Update equality and hashCode to include all fields',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final equalityMethod = getEqualityMethod(classDecl);
    final hashCodeMethod = getHashCodeMethod(classDecl);

    if (equalityMethod == null || hashCodeMethod == null) return;

    if (getMissingFieldsInEquality(classDecl, equalityMethod).isEmpty &&
        getMissingFieldsInHashCode(classDecl, hashCodeMethod).isEmpty) {
      return;
    }

    final className = getClassName(classDecl);
    final classFields = getClassFields(classDecl);

    await builder.addDartFileEdit(file, (builder) {
      final equalityRange = equalityMethod.offset;
      final equalityLength = equalityMethod.length;

      final equalitySnippet = buildEqualitySnippet(
        className,
        classFields,
        builder: builder,
      );

      builder.addSimpleReplacement(
        SourceRange(equalityRange, equalityLength),
        equalitySnippet,
      );

      final hashCodeRange = hashCodeMethod.offset;
      final hashCodeLength = hashCodeMethod.length;

      final hashCodeSnippet = buildHashCodeSnippet(
        classFields,
        builder: builder,
      );

      builder.addSimpleReplacement(
        SourceRange(hashCodeRange, hashCodeLength),
        hashCodeSnippet,
      );
      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
