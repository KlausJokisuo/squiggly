import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:squiggly/utils.dart';

Set<String> _missingInEquality(
  ClassDeclaration classDecl,
  MethodDeclaration equalityMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final equalityFieldNames = getFieldsInFunctionBody(equalityMethod);

  return classFieldNames
      .where((field) => !equalityFieldNames.contains(field))
      .toSet();
}

Set<String> _missingInHashCode(
  ClassDeclaration classDecl,
  MethodDeclaration hashCodeMethod,
) {
  final classFieldNames = getClassFields(classDecl).map((field) => field.name);

  final hashCodeFieldNames = getFieldsInFunctionBody(hashCodeMethod);

  return classFieldNames
      .where((field) => !hashCodeFieldNames.contains(field))
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

    final equalityMethod = getEqualityMethod(node);
    final hashCodeMethod = getHashCodeMethod(node);

    if (equalityMethod == null || hashCodeMethod == null) {
      return;
    }

    final missingInEquality = _missingInEquality(node, equalityMethod);
    final missingInHashCode = _missingInHashCode(node, hashCodeMethod);

    if (missingInEquality.isNotEmpty) {
      rule.reportAtToken(
        equalityMethod.name,
        arguments: [missingInEquality.toList().join(', ')],
      );
    }

    if (missingInHashCode.isNotEmpty) {
      rule.reportAtToken(
        hashCodeMethod.name,
        arguments: [missingInHashCode.toList().join(', ')],
      );
    }
  }
}

class EqualityIncompleteRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'equality_incomplete',
    'All fields should be included in equality and hashCode: {0}',
    correctionMessage: 'Update == and hashCode to include all fields.',
  );

  EqualityIncompleteRule()
    : super(
        name: 'equality_incomplete',
        description:
            'Ensures all fields are included in equality and hashCode overrides.',
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
