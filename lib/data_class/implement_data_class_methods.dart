import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:squiggly/utils.dart';

class ImplementDataClassMethods extends ResolvedCorrectionProducer {
  ImplementDataClassMethods({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => FixKind(
    'dart.assist.implement_data_class_methods',
    DartFixKindPriority.standard,
    'Implement data class methods',
  );

  @override
  AssistKind? get assistKind => AssistKind(
    'dart.assist.implement_data_class_methods',
    DartFixKindPriority.standard,
    'Implement Data class methods',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    // Determine which snippets are needed
    final needEquality =
        (getEqualityMethod(classDecl) == null ||
        getHashCodeMethod(classDecl) == null);
    final needCopyWith = getCopyWithMethod(classDecl) == null;

    if (!needEquality && !needCopyWith) return;

    final className = getClassName(classDecl);
    final classFieldNames = getClassFields(classDecl).map((f) => f.name);

    await builder.addDartFileEdit(file, (builder) {
      final insertOffset = classDecl.rightBracket.offset;
      builder.addInsertion(insertOffset, (builder) {
        // equality + hashCode
        if (needEquality) {
          builder.write(
            buildEqualityAndHashCodeSnippet(className, classFieldNames),
          );
        }

        // copyWith
        if (needCopyWith) {
          final snippet = buildCopyWithSnippet(classDecl);
          if (snippet != null) {
            if (needEquality) builder.writeln();
            builder.write(snippet);
          }
        }
      });

      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
