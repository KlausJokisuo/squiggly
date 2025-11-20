import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:squiggly/utils.dart';

class UpdateToString extends ResolvedCorrectionProducer {
  UpdateToString({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => FixKind(
    'dart.assist.update_tostring',
    DartFixKindPriority.standard,
    'Update toString to include all fields',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();

    if (classDecl == null) return;

    final toStringMethod = getToStringMethod(classDecl);

    if (toStringMethod == null) return;

    final missingInToString = getMissingFieldsInToString(
      classDecl,
      toStringMethod,
    );

    if (missingInToString.isEmpty) return;

    final className = getClassName(classDecl);
    final classFieldNames = getClassFields(
      classDecl,
    ).map((field) => field.name);

    await builder.addDartFileEdit(file, (builder) {
      final replacementSnippet = buildToStringSnippet(
        className,
        classFieldNames,
      );

      builder.addSimpleReplacement(
        SourceRange(toStringMethod.offset, toStringMethod.length),
        replacementSnippet,
      );
      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
