import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:squiggly/utils.dart';

class AddCopyWith extends ResolvedCorrectionProducer {
  AddCopyWith({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => FixKind(
    'dart.assist.add_class_copywith',
    DartFixKindPriority.standard,
    'Add copyWith method',
  );

  @override
  AssistKind get assistKind => AssistKind(
    'dart.assist.add_class_copywith',
    DartFixKindPriority.standard,
    'Add copyWith method',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    if (getCopyWithMethod(classDecl) != null) return;

    await builder.addDartFileEdit(file, (builder) {
      final insertOffset = classDecl.rightBracket.offset;

      builder.addInsertion(insertOffset, (builder) {
        final snippet = buildCopyWithSnippet(classDecl);
        if (snippet != null) builder.write(snippet);
      });

      builder.format(SourceRange(0, unitResult.content.length));
    });
  }
}
