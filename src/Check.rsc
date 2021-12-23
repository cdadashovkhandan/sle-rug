module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str id, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv envs = {};
  envs += { <q.src, id, name, typeOf(\type) > | /q:computedQuest(name, id, \type, _) <- f };
  envs += { <q.src, id, name, typeOf(\type) > | /q:quest(name, id, \type) <- f };
  return envs;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += { *check(q, tenv, useDef) | /AQuestion q <- f };
  msgs += { *check(expr, tenv, useDef) | /AExpr expr <- f };
  return msgs; 
}

// [X] produce an error if there are declared questions with the same name but different types.
// [X] duplicate labels should trigger a warning 
// [X] the declared type computed questions should match the type of the expression.

set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};

  if (computedQuest(qid,qname,qtype,_) := q || quest(qid,qname,qtype) := q) {
    qsrc = q.src;

    for (<d, i, l, t> <- tenv) {
      if (qid == i && typeOf(qtype) != t) {
        messages += { error("Name redefined at: <qsrc>", qsrc) };
        // TOO-DONE: messages += { info("Name initially defined at: <d>", d) };
      }
      if (qname == l) {
        messages += { warning("Label already exists at: <d>", qsrc)};
      }
    }

    if (computedQuest(_, _, t_raw, expr) := q, t := typeOf(t_raw), <_,_,_,t> <- tenv) {
      if (typeOf(expr, tenv, useDef) != t) {
        messages += { error("Expression does not match the declared type.", qsrc) };
      }
    }
  }

  return messages;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    default:
      if (typeOf(e, tenv, useDef) == tunknown()) {
        msgs += { error("Invalid expression type", e.src)};
      }
  }
  
  return msgs; 
}

Type assertCompType(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
  if (typeOf(lhs, tenv, useDef) == tint()
  && typeOf(rhs, tenv, useDef) == tint()) {
    return tbool();
  } else {
    return tunknown();
  }
}

Type assertType(AExpr lhs, AExpr rhs, Type typ, TEnv tenv, UseDef useDef) {
  if (typeOf(lhs, tenv, useDef) == typ
  && typeOf(rhs, tenv, useDef) == typ) {
    return typ;
  } else {
    return tunknown();
  }
}

Type assertType(AExpr expr, Type typ, TEnv tenv, UseDef useDef) {
  if (typeOf(expr, tenv, useDef) == typ) {
    return typ;
  } else {
    return tunknown();
  }
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  println("Typeof called");
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case litInt(_): return tint();
    case litBool(_): return tbool();
    case litStr(_): return tstr();
    case neg(expr): return assertType(expr, tint(), tenv, useDef);
    case not(expr): return assertType(expr, tbool(), tenv, useDef);
    case mul(lhs, rhs): return assertType(lhs, rhs, tint(), tenv, useDef);
    case div(lhs, rhs): return assertType(lhs, rhs, tint(), tenv, useDef);
    case plus(lhs, rhs): return assertType(lhs, rhs, tint(), tenv, useDef);
    case min(lhs, rhs): return assertType(lhs, rhs, tint(), tenv, useDef);
    case and(lhs, rhs): return assertType(lhs, rhs, tbool(), tenv, useDef);
    case or(lhs, rhs): return assertType(lhs, rhs, tbool(), tenv, useDef);
    case lt(lhs, rhs): return assertCompType(lhs, rhs, tenv, useDef);
    case leq(lhs, rhs): return assertCompType(lhs, rhs, tenv, useDef);
    case gt(lhs, rhs): return assertCompType(lhs, rhs, tenv, useDef);
    case geq(lhs, rhs): return assertCompType(lhs, rhs, tenv, useDef);
    case equ(lhs, rhs): return (typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)) ? tbool() : tunknown();
    case neq(lhs, rhs): return (typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)) ? tbool() : tunknown();
  }
  return tunknown(); 
}

Type typeOf(AType t) {
  switch (t.t) {
    case "integer" : return tint();
    case "boolean" : return tbool();
    case "string" : return tstr();
    default: return tunknown();
  }
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

