import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:squiggly/utils.dart';

class UpdateCopyWith extends ResolvedCorrectionProducer {
  UpdateCopyWith({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => FixKind(
    'dart.assist.update_class_copywith',
    DartFixKindPriority.standard,
    'Update copyWith to include all fields',
  );

  @override
  AssistKind get assistKind => AssistKind(
    'dart.assist.update_class_copywith',
    DartFixKindPriority.standard,
    'Update copyWith to include all fields',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final copyWithMethod = getCopyWithMethod(classDecl);

    if (copyWithMethod == null) return;

    if (getMissingFieldsInCopyWith(classDecl, copyWithMethod).isEmpty) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      final methodRange = copyWithMethod.offset;
      final methodLength = copyWithMethod.length;

      final replacementSnippet = buildCopyWithSnippet(classDecl);

      if (replacementSnippet != null) {
        builder.addSimpleReplacement(
          SourceRange(methodRange, methodLength),
          replacementSnippet,
        );

        builder.format(SourceRange(0, unitResult.content.length));
      }
    });
  }
}
