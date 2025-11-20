import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'package:squiggly/utils.dart';

class AddEquality extends ResolvedCorrectionProducer {
  AddEquality({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => AssistKind(
    'dart.assist.add_class_equality',
    DartFixKindPriority.standard,
    'Add equality and hashCode overrides',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final hasEqualityOverride = getEqualityMethod(classDecl) != null;
    final hasHashCodeOverride = getHashCodeMethod(classDecl) != null;

    if (hasEqualityOverride && hasHashCodeOverride) return;

    final className = getClassName(classDecl);
    final classFieldNames = getClassFields(
      classDecl,
    ).map((field) => field.name);

    await builder.addDartFileEdit(file, (builder) {
      final insertOffset = classDecl.rightBracket.offset;
      builder.addInsertion(insertOffset, (builder) {
        builder.write(
          buildEqualityAndHashCodeSnippet(className, classFieldNames),
        );
      });

      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
