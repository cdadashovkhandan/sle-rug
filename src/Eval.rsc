module Eval

import IO;
import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
    = vInt(int n)
    | vBool(bool b)
    | vStr(str s)
    ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
    = input(str question, Value \value);
    
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
Value getDefault(AType t) {
    switch (t) {
        case qlType("integer"): return vInt(0);
        case qlType("string"): return vStr("");
        case qlType("boolean"): return vBool(false);
        default: throw "Unknown type\n";
    }
}

VEnv initialEnv(AForm f) {
    venv = ();
    for (/quest(_,id,t) <- f) {
        venv += (id : getDefault(t));
    }
    for (/computedQuest(_,id,t,_) <- f) {
        venv += (id : getDefault(t));
    }
    return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
    println("Solving");
    return solve (venv) {
        venv = evalOnce(f, inp, venv);
    }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
    println("Not even once");
    for (/AQuestion q <- f) {
        //println("Question: <q.id>:<q.\type>");
        venv += eval(q, inp, venv);
    }
    return venv;
}

bool eqTypes(Value lhs, Value rhs) {
    if (vInt(_) := lhs && vInt(_) := rhs) return true;
    if (vBool(_) := lhs && vBool(_) := rhs) return true;
    if (vStr(_) := lhs && vStr(_) := rhs) return true;
    return false;
}

VEnv eval(AQuestion q, Input inp:input(inId, inVal), VEnv venv) {
    // evaluate conditions for branching,
    // evaluate inp and computed questions to return updated VEnv

    switch (q) {

        // Evaluating questions
        case quest(_,id,t): {
            if (id == inId) {
                if (!eqTypes(getDefault(t), inVal)) {
                    throw "Type mismatch at: <q>";
                }
                venv += ( inId : inVal );
            }
        }

        // Evaluating computed questions
        case computedQuest(_,id,_,qexpr):
            venv += (id : eval(qexpr, venv)); 
        
        
        case ifThen(guard, qList): {
            vGuard = eval(guard, venv).b;
            if (vGuard) {
                for (AQuestion q2 <- qList) {
                    venv += eval(q2, inp, venv);
                }
            }
        }

        case ifThenElse(guard, thenQs, elseQs): {
            vGuard = eval(guard, venv).b;
            if (vGuard) {
                for (AQuestion q2 <- thenQs) {
                    venv += eval(q2, inp, venv);
                }
            } else {
                for (AQuestion q2 <- elseQs) {
                    venv += eval(q2, inp, venv);
                }
            }
        }
    }
    return venv; 
}

Value eval(AExpr e, VEnv venv) {
    switch (e) {
        case ref(id(str x)): return venv[x];
        case litInt(v): return vInt(v);
        case litBool(v): return vBool(v); 
        case litStr(v): return vStr(v);
        case neg(a) : {
            aVal = eval(a, venv).n;
            return vInt(-aVal);
        } 
        case not(a) : {
            aVal = eval(a, venv).b;
            return vBool(!aVal);
        } 
        case mul(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vInt(lVal * rVal);
        }
        case div(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vInt(lVal / rVal);
        }
        case plus(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vInt(lVal + rVal);
        }
        case min(lhs, rhs) : {
            println("<lhs> - <rhs>");
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vInt(lVal - rVal);
        }
        case lt(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vBool(lVal < rVal);
        }
        case leq(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vBool(lVal <= rVal);
        }
        case gt(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vBool(lVal > rVal);
        }
        case geq(lhs, rhs) : {
            lVal = eval(lhs, venv).n;
            rVal = eval(rhs, venv).n;
            return vBool(lVal >= rVal);
        }
        case equ(lhs, rhs) : {
            return vBool(eval(lhs, venv) == eval(rhs, venv));
        }
        case neq(lhs, rhs) : {
            return vBool(eval(lhs, venv) != eval(rhs, venv));
        }
        case and(lhs, rhs) : {
            lVal = eval(lhs, venv).b;
            rVal = eval(rhs, venv).b;
            return vBool(lVal && rVal);
        }
        case or(lhs, rhs) : {
            lVal = eval(lhs, venv).b;
            rVal = eval(rhs, venv).b;
            return vBool(lVal || rVal);
        }

        default: throw "Invalid expression <e>";
    }
}
