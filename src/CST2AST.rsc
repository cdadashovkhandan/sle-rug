module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import IO;
import Type;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf)
  = cst2ast(sf.top);

AForm cst2ast(x:(Form)`form <Id i> <Block b>`)
  = form("<i>", cst2ast(b), src=x@\loc);

AQuestion cst2ast(Question q) {
  switch (q) {
    case k:(Question)`<Str s> <Id i> : <Type t> = <Expr e>`: return computedQuest("<s>", "<i>", cst2ast(t), cst2ast(e), src=k@\loc);
    case k:(Question)`<Str s> <Id i> : <Type t>`: return quest("<s>", "<i>", cst2ast(t), src=k@\loc);
    case k:(Question)`if (<Expr g>) <Block b>`: return ifThen(cst2ast(g), cst2ast(b), src=k@\loc);
    case k:(Question)`if (<Expr g>) <Block b> else <Block c>`: return ifThenElse(cst2ast(g), cst2ast(b), cst2ast(c), src=k@\loc);
    default: throw "Invalid question: <q>";
  }
}

list[AQuestion] cst2ast((Block)`{ <Question* qs> }`)
  = [ cst2ast(q) | Question q <- qs ];



AExpr cst2ast(Expr expr) {
  switch (expr) {
    case (Expr)`(<Expr e>)`: return cst2ast(e);
    case (Expr)`<Id x>`: return ref(id("<x>", src=expr@\loc), src=expr@\loc);
    case (Expr)`<Int i>`: return litInt(cst2ast(i), src=expr@\loc);
    case (Expr)`<Bool b>`: return litBool(cst2ast(b), src=expr@\loc);
    case (Expr)`<Str s>`: return litStr(cst2ast(s), src=expr@\loc);
    case (Expr)`- <Expr e>`: return neg(cst2ast(e), src=expr@\loc);
    case (Expr)`! <Expr e>`: return not(cst2ast(e), src=expr@\loc);
    case (Expr)`<Expr a> * <Expr b>`: return mul(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> / <Expr b>`: return div(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> + <Expr b>`: return plus(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> - <Expr b>`: return min(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> \< <Expr b>`: return lt(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> \<= <Expr b>`: return leq(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> \> <Expr b>`: return gt(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> \>= <Expr b>`: return geq(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> == <Expr b>`: return equ(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> != <Expr b>`: return neq(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> && <Expr b>`: return and(cst2ast(a), cst2ast(b), src=expr@\loc);
    case (Expr)`<Expr a> || <Expr b>`: return or(cst2ast(a), cst2ast(b), src=expr@\loc);
    default: throw "Unhandled expression: <expr>";
  }
}

AType cst2ast(Type t) = qlType("<t>", src=t@\loc);

AId cst2ast(Id i) = id("<i>", src=i@\loc);

int cst2ast(Int i) = toInt("<i>");

bool cst2ast((Bool)`true`) = true;
bool cst2ast((Bool)`false`) = false;

str cst2ast(Str s) = "<s>";
