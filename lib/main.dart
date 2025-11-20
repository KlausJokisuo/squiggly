import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:squiggly/equality/add_equality.dart';
import 'package:squiggly/equality_incomplete/equality_incomplete.dart';
import 'package:squiggly/equality_incomplete/update_equality.dart';
import 'package:squiggly/tostring/add_tostring.dart';
import 'package:squiggly/copywith/add_copywith.dart';
import 'package:squiggly/copywith_incomplete/copywith_incomplete.dart';
import 'package:squiggly/copywith_incomplete/update_copywith.dart';
import 'package:squiggly/data_class/implement_data_class_methods.dart';
import 'package:squiggly/tostring_incomplete/tostring_incomplete.dart';
import 'package:squiggly/tostring_incomplete/update_tostring.dart';

final plugin = SquigglyPlugin();

class SquigglyPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    // Equality - available as assist
    registry.registerAssist(AddEquality.new);

    // ToString - available as assist
    registry.registerAssist(AddToString.new);

    // CopyWith - available as assist
    registry.registerAssist(AddCopyWith.new);

    // Implement Data Class Methods - available as assist
    registry.registerAssist(ImplementDataClassMethods.new);

    // Equality Incomplete - lint + fix
    registry.registerLintRule(EqualityIncompleteRule());
    registry.registerFixForRule(
      EqualityIncompleteRule.code,
      UpdateEquality.new,
    );

    // CopyWith Incomplete - lint + fix
    registry.registerLintRule(CopyWithIncompleteRule());
    registry.registerFixForRule(
      CopyWithIncompleteRule.code,
      UpdateCopyWith.new,
    );

    // ToString Incomplete - lint + fix
    registry.registerLintRule(IncompleteClassToStringRule());
    registry.registerFixForRule(
      IncompleteClassToStringRule.code,
      UpdateToString.new,
    );
  }

  @override
  String get name => 'squiggly';
}
