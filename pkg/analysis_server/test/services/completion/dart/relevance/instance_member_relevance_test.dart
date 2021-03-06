// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberRelevanceTest);
  });
}

@reflectiveTest
class InstanceMemberRelevanceTest extends AbstractCompletionDriverTest {
  @override
  AnalysisServerOptions get serverOptions =>
      AnalysisServerOptions()..useNewRelevance = true;

  @override
  bool get supportsAvailableSuggestions => true;

  /// Assert that all of the given completions were produced and that the
  /// suggestions are ordered in decreasing order based on relevance scores.
  void assertOrder(List<CompletionSuggestion> suggestions) {
    var length = suggestions.length;
    expect(length, greaterThan(1),
        reason: 'Test must specify more than one suggestion');
    var inOrder = true;
    var previous = suggestions[0];
    for (var i = 1; i < length; i++) {
      var current = suggestions[i];
      if (current.relevance >= previous.relevance) {
        inOrder = false;
      }
      previous = current;
    }
    if (!inOrder) {
      suggestions.sort((first, second) => second.relevance - first.relevance);
      var buffer = StringBuffer();
      buffer.writeln('Actual sort order does not match expected order.');
      buffer.writeln('To accept the actual sort order, use:');
      buffer.writeln();
      buffer.writeln('    assertOrder([');
      for (var suggestion in suggestions) {
        var completion = suggestion.completion;
        buffer.writeln("      suggestionWith(completion: '$completion'),");
      }
      buffer.writeln('    ]);');
      fail(buffer.toString());
    }
  }

  Future<void> test_contextType() async {
    await addTestFile(r'''
class A {}
class B extends A {}
class C extends B {}
class D {}

class E {
  A a() {}
  B b() {}
  C c() {}
  D d() {}
}

void f(B b) {}
void g(E e) {
  f(e.^);
}
''');
    assertOrder([
      suggestionWith(completion: 'b'), // same
      suggestionWith(completion: 'c'), // subtype
      suggestionWith(completion: 'd'), // unrelated
      suggestionWith(completion: 'a'), // supertype
    ]);
  }

  Future<void> test_elementKind() async {
    await addTestFile('''
class A {
  int get g => 0;
  void m() { }
  set s(int x) {}
}

void f(A a) {
  a.^
}
''');
    // The order below is dependent on generated data, so it can validly change
    // when the data is re-generated.
    assertOrder([
      suggestionWith(completion: 'g'),
      suggestionWith(completion: 's'),
      suggestionWith(completion: 'm'),
    ]);
  }

  Future<void> test_hasDeprecated() async {
    await addTestFile('''
class C {
  void a() {}
  @deprecated
  void b() {}
}

void f(C c) {
  c.^
}
''');
    assertOrder([
      suggestionWith(completion: 'a'),
      suggestionWith(completion: 'b'),
    ]);
  }

  Future<void> test_inheritanceDepth() async {
    await addTestFile('''
class A {
  void a() { }
}

class B extends A {
  void b() { }
}

void f(B b) {
  b.^
}
''');
    assertOrder([
      suggestionWith(completion: 'b'),
      suggestionWith(completion: 'a'),
      suggestionWith(completion: 'toString'),
    ]);
  }

  Future<void> test_startsWithDollar() async {
    await addTestFile(r'''
class A {
  void a() { }
  void $b() { }
}

void f(A a) {
  a.^
}
''');
    assertOrder([
      suggestionWith(completion: 'a'),
      suggestionWith(completion: r'$b'),
    ]);
  }

  Future<void> test_superMatches() async {
    await addTestFile('''
class A {
  void a() { }
  void b() { }
}

class B extends A {
  void b() {
    super.^
  }
}
''');
    assertOrder([
      suggestionWith(completion: 'b'),
      suggestionWith(completion: 'a'),
    ]);
  }
}
