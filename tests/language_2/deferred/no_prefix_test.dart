// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Loading a deferred library without prefix is not allowed.
import "constraints_lib2.dart"
  deferred
//^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_PREFIX_IN_DEFERRED_IMPORT
// [cfe] Deferred imports should have a prefix.
    ;

void main() {}
