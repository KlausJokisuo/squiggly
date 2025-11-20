import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'package:squiggly/utils.dart';

class AddToString extends ResolvedCorrectionProducer {
  AddToString({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => AssistKind(
    'dart.assist.add_class_tostring',
    DartFixKindPriority.standard,
    'Add toString override',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    if (getToStringMethod(classDecl) != null) return;

    final className = getClassName(classDecl);
    final classFieldNames = getClassFields(
      classDecl,
    ).map((field) => field.name);

    await builder.addDartFileEdit(file, (builder) {
      final insertOffset = classDecl.rightBracket.offset;
      builder.addInsertion(insertOffset, (builder) {
        builder.write(buildToStringSnippet(className, classFieldNames));
      });

      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
