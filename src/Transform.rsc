module Transform

import Syntax;
import Resolve;
import AST;
import IO;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
 /*
  Recursively traverse the AST while keeping track if if-depth.
 */
 
AForm flatten(AForm f) {
    qs = [];
    for (AQuestion q <- f.questions) {
        qs += flat(q, litBool(true), []);
    }
    f.questions = qs;
    return f;
}

list[AQuestion] flat(AQuestion q, AExpr guac, list[AQuestion] qs) {
    switch (q) {
        case quest(_,_,_):
            qs += ifThen(guac, [q]);
        case computedQuest(_,_,_,_):
            qs += ifThen(guac, [q]);
        case ifThen(guard, iqs):
            qs += [*flat(iq, and(guac, guard), qs) | iq <- iqs];
        case ifThenElse(guard, iqs, eqs): {
            qs += [*flat(iq, and(guac, guard), qs) | iq <- iqs];
            qs += [*flat(eq, and(guac, not(guard)), qs) | eq <- eqs];
    	}
    }
    return qs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */

start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
    set[loc] toRename = {};
    println("Hey");

    if (useOrDef in useDef<1>) { // Def
        // Add given location
        toRename += {useOrDef};
        // Fetch uses matching the definition
        toRename += { use | <loc use, useOrDef> <- useDef };

    } else if (useOrDef in useDef<0>) { // Use
        // Fetch definition from use location
        if (<useOrDef, loc def> <- useDef) {
            // Fetch uses matching the definition
            toRename += { use | <loc use, def> <- useDef };
        }

    } else {
        return f;
    }

    println("Lucaras");
    return visit (f) {
        case Id x => [Id]newName
            when x@src in toRename
    }
}
