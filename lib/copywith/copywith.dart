import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:squiggly/utils.dart';

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!context.isInLibDir) {
      return;
    }

    if (getCopyWithMethod(node) != null) return;

    rule.reportAtToken(node.name);
  }
}

class CopyWithRule extends AnalysisRule {
  static const LintCode code = LintCode('copywith', 'Add a copyWith method');

  CopyWithRule()
    : super(name: 'copywith', description: 'Add a copyWith method.');

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
