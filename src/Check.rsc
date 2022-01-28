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
    envs += { <q.src, id, name, getType(\type) > | /q:computedQuest(name, id, \type, _) <- f };
    envs += { <q.src, id, name, getType(\type) > | /q:quest(name, id, \type) <- f };
    return envs;
}

// Error-check the whole form
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
    set[Message] msgs = {};
    msgs += { *check(q, tenv, useDef) | /AQuestion q <- f };
    msgs += { *check(expr, tenv, useDef) | /AExpr expr <- f };
    return msgs; 
}

// Error-heck a question
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
    set[Message] messages = {};

    if (computedQuest(qid,qname,qtype,_) := q
    ||  quest(qid,qname,qtype) := q) {

        // Check for existing definitions.
        for (<_, ident, label, typ> <- tenv) {

            // If a definition already exists and it is of a different type
            if (qid == ident && getType(qtype) != typ) {
                messages += { error("Name redefined", q.src) };
            }
            // If a definition already exists and it is of the same type
            if (qname == label) {
                messages += { warning("Label already exists", q.src)};
            }
        }

        if (computedQuest(_, _, typ, expr) := q, t := getType(typ), <_,_,_,t> <- tenv) {
            if (getType(expr, tenv, useDef) != t) {
                messages += { error("Expression does not match the declared type.", q.src) };
            }
        }
    }
    return messages;
}

// Check operand compatibility with operators.
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
    set[Message] msgs = {};
    
    switch (e) {
        case ref(AId x):
            msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
        default:
            if (getType(e, tenv, useDef) == tunknown()) {
                msgs += { error("Invalid expression type", e.src)};
            }
    }
    
    return msgs; 
}

Type assertComparisonType(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
    if (getType(lhs, tenv, useDef) == tint()
    && getType(rhs, tenv, useDef) == tint()) {
        return tbool();
    } else {
        return tunknown();
    }
}

Type assertType(AExpr lhs, AExpr rhs, Type typ, TEnv tenv, UseDef useDef) {
    if (getType(lhs, tenv, useDef) == typ
    && getType(rhs, tenv, useDef) == typ) {
        return typ;
    } else {
        return tunknown();
    }
}

Type assertType(AExpr expr, Type typ, TEnv tenv, UseDef useDef) {
    if (getType(expr, tenv, useDef) == typ) {
        return typ;
    } else {
        return tunknown();
    }
}

Type getType(AExpr e, TEnv tenv, UseDef useDef) {
    switch (e) {
        case ref(id(_, src = loc u)):  
            if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
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
        case lt(lhs, rhs): return assertComparisonType(lhs, rhs, tenv, useDef);
        case leq(lhs, rhs): return assertComparisonType(lhs, rhs, tenv, useDef);
        case gt(lhs, rhs): return assertComparisonType(lhs, rhs, tenv, useDef);
        case geq(lhs, rhs): return assertComparisonType(lhs, rhs, tenv, useDef);
        case equ(lhs, rhs): return (getType(lhs, tenv, useDef) == getType(rhs, tenv, useDef)) ? tbool() : tunknown();
        case neq(lhs, rhs): return (getType(lhs, tenv, useDef) == getType(rhs, tenv, useDef)) ? tbool() : tunknown();
    }
    return tunknown(); 
}

Type getType(AType t) {
    switch (t.t) {
        case "integer" : return tint();
        case "boolean" : return tbool();
        case "string" : return tstr();
        default: return tunknown();
    }
}
 

