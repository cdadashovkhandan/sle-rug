module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

// Top level node
data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

// Question + conditionals
data AQuestion(loc src = |tmp:///|)
  = computedQuest(str name, str id, AType \type, AExpr)
  | quest(str name, str id, AType \type)
  | ifThen(AExpr guard, list[AQuestion] questions)
  | ifThenElse(AExpr guard, list[AQuestion] ifQuest, list[AQuestion] elseQuest)
  ; 

// Expressions
data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | litInt(int i)
  | litBool(bool c)
  | litStr(str s)
  | neg(AExpr e)
  | not(AExpr e)
  | mul(AExpr a, AExpr b)
  | div(AExpr a, AExpr b)
  | plus(AExpr a, AExpr b)
  | min(AExpr a, AExpr b)
  | lt(AExpr a, AExpr b)
  | leq(AExpr a, AExpr b)
  | gt(AExpr a, AExpr b)
  | geq(AExpr a, AExpr b)
  | equ(AExpr a, AExpr b)
  | neq(AExpr a, AExpr b)
  | and(AExpr a, AExpr b)
  | or(AExpr a, AExpr b)
  ;

// Identifier
data AId(loc src = |tmp:///|)
  = id(str name);

// Data types and the type itself:

data AType(loc src = |tmp:///|)
  = qlType(str t);

data AInt(loc src = |tmp:///|)
  = aInt(str t);

data ABool(loc src = |tmp:///|)
  = aBool(str t);
