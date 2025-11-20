import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:squiggly/utils.dart';

Set<String> _missingInToString(
  ClassDeclaration classDecl,
  MethodDeclaration toStringMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final toStringFieldNames = getFieldsInFunctionBody(toStringMethod);

  return classFieldNames
      .where((field) => !toStringFieldNames.contains(field))
      .toSet();
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!context.isInLibDir) {
      return;
    }

    final toStringMethod = getToStringMethod(node);

    if (toStringMethod == null) return;

    final missingInToString = _missingInToString(node, toStringMethod);

    if (missingInToString.isNotEmpty) {
      rule.reportAtToken(
        toStringMethod.name,
        arguments: [missingInToString.toList().join(', ')],
      );
    }
  }
}

class IncompleteClassToStringRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'tostring_incomplete',
    'All fields should be included in toString: {0}',
    correctionMessage: 'Update toString to include all fields.',
  );

  IncompleteClassToStringRule()
    : super(
        name: 'tostring_incomplete',
        description: 'Ensures all fields are included in toString override.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}
