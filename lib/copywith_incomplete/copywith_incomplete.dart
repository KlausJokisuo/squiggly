import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:squiggly/utils.dart';

Set<String> _missingInCopyWith(
  ClassDeclaration classDecl,
  MethodDeclaration copyWithMethod,
) {
  final classFieldNames = getClassFields(
    classDecl,
    constructorOnly: true,
  ).map((field) => field.name);

  final copyWithParams = _getCopyWithParameters(copyWithMethod);

  return classFieldNames
      .where((field) => !copyWithParams.contains(field))
      .toSet();
}

Set<String> _getCopyWithParameters(MethodDeclaration method) {
  final params = <String>{};
  final paramList = method.parameters?.parameters;
  if (paramList != null) {
    for (final param in paramList) {
      if (param is DefaultFormalParameter) {
        params.add(param.name!.lexeme);
      } else if (param is SimpleFormalParameter) {
        params.add(param.name!.lexeme);
      }
    }
  }
  return params;
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

    final copyWithMethod = getCopyWithMethod(node);

    if (copyWithMethod == null) {
      return;
    }

    final missingInCopyWith = _missingInCopyWith(node, copyWithMethod);

    if (missingInCopyWith.isNotEmpty) {
      rule.reportAtToken(
        copyWithMethod.name,
        arguments: [missingInCopyWith.toList().join(', ')],
      );
    }
  }
}

class CopyWithIncompleteRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'copywith_incomplete',
    'All fields should be included in copyWith: {0}',
    correctionMessage: 'Update copyWith to include all fields.',
  );

  CopyWithIncompleteRule()
    : super(
        name: 'copywith_incomplete',
        description: 'Ensures all fields in are included in copyWith method.',
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
