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

    final equalityMethod = getEqualityMethod(classDecl);
    final hashCodeMethod = getHashCodeMethod(classDecl);

    final hasEqualityOverride = equalityMethod != null;
    final hasHashCodeOverride = hashCodeMethod != null;

    if (hasEqualityOverride && hasHashCodeOverride) return;

    final className = getClassName(classDecl);
    final classFields = getClassFields(classDecl);

    await builder.addDartFileEdit(file, (fileBuilder) {
      final snippet = buildEqualityAndHashCodeSnippet(
        className,
        classFields,
        builder: fileBuilder,
      );

      // If both methods exist, replace them
      if (equalityMethod != null && hashCodeMethod != null) {
        final startOffset = equalityMethod.offset;
        final endOffset = hashCodeMethod.offset + hashCodeMethod.length;
        final length = endOffset - startOffset;

        fileBuilder.addSimpleReplacement(
          SourceRange(startOffset, length),
          snippet,
        );
      } else if (equalityMethod != null) {
        // Only equality exists, replace it with both methods
        fileBuilder.addSimpleReplacement(
          SourceRange(equalityMethod.offset, equalityMethod.length),
          snippet,
        );
      } else if (hashCodeMethod != null) {
        // Only hashCode exists, replace it with both methods
        fileBuilder.addSimpleReplacement(
          SourceRange(hashCodeMethod.offset, hashCodeMethod.length),
          snippet,
        );
      } else {
        // Neither exists, insert at end of class
        final insertOffset = classDecl.rightBracket.offset;
        fileBuilder.addInsertion(insertOffset, (builder) {
          builder.write(snippet);
        });
      }

      fileBuilder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
