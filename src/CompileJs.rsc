module CompileJs

import AST;
import Resolve;
import IO;
import List; //TODO: REMOVE LATER
import String;

// NOTE: THIS CAN BE REMOVED
//  HTML5Node htmlQuestion(AQuestion q, bool computed) {
//    return input(type("text"), id("<q.\type>"), name("<q.label>"), class("ql-enabled"))


str cleanLoc(loc src) {
    str inp = "<src>";
    inp = replaceAll(inp, "/", "");
    inp = replaceAll(inp, "\<", "");
    inp = replaceAll(inp, "\>", "");
    inp = replaceAll(inp, " ", "");
    inp = replaceAll(inp, ".", "");
    inp = replaceAll(inp, ":", "");
    inp = replaceAll(inp, "-", "");
    inp = replaceAll(inp, ",", "");
    inp = replaceAll(inp, "(", "");
    inp = replaceAll(inp, ")", "");
    inp = replaceAll(inp, "|", "");
    return inp;
}

str form2js(AForm f) {
    js_str = "";
    for (AQuestion q <- f.questions) {
        js_str += quest2js(q, f);
    }
    return js_str;
}

str quest2js(AQuestion qu, AForm fo) {
    switch (qu) {
        case computedQuest(_,id,ty,expr): {
            str accessor = typeAccessor(ty);
            return  "$(\'#<fo.name>\').on(\'formUpdated\', function (event) {
                    '   $(\'#<id>\')[0].<accessor> = <expr2js(expr, fo)>;
                    '});\n";
        }
        case quest(_,id,ty): {
            str accessor = typeAccessor(ty);
            return  "$(\'#<id>\').on(\'change\', function (event) {
                    '   $(\'#<fo.name>\').trigger(\'formUpdated\');
                    '});\n";
        }
        case ifThen(guard,iqs): {
            output = "$(\'#<fo.name>\').on(\'formUpdated\', function (event) {
                    '   if (<expr2js(guard, fo)>) {
                    '       $(\'#<cleanLoc(qu.src)>\').addClass(\'true\');

                    '   } else {
                    '       $(\'#<cleanLoc(qu.src)>\').removeClass(\'true\');

                    '   }
                    '});\n";
            // build js code for every question inside the if
            for (AQuestion iq <- iqs) {
                output += "\n" + quest2js(iq, fo) + ";\n";
            }
            return output;
        }
        case ifThenElse(guard,iqs,eqs): {
            output = "$(\'#<fo.name>\').on(\'formUpdated\', function (event) {
                    '   if (<expr2js(guard, fo)>) {
                    '       $(\'#<cleanLoc(qu.src)>\').addClass(\'true\');

                    '   } else {
                    '       $(\'#<cleanLoc(qu.src)>\').removeClass(\'true\');

                    '   }
                    '});\n";
            // build js code for every question inside the if AND the else
            // I don't think their location matters anyway
            for (AQuestion iq <- iqs + eqs) { // concat the two lists
                output += "\n" + quest2js(iq, fo) + ";\n";
            }
            return output;
        }
    }
    return "";
}

str expr2js(AExpr e, AForm f) {
    switch (e) {
        case ref(id(name, src = loc u)): {
            AType ty = getType(name, f);
            str accessor = typeAccessor(ty);
            return "$(\'#<name>\')[0].<accessor>";
        }
        case litInt(val): return "<val>";
        case litBool(val): return "<val>";
        case litStr(val): return "<val>";
        case neg(expr): return "-<expr2js(expr, f)>";
        case not(expr): return "!<expr2js(expr, f)>";
        case mul(lhs, rhs): return "<expr2js(lhs, f)> * <expr2js(rhs, f)>";
        case div(lhs, rhs): return "<expr2js(lhs, f)> / <expr2js(rhs, f)>";
        case plus(lhs, rhs): return "<expr2js(lhs, f)> + <expr2js(rhs, f)>";
        case min(lhs, rhs): return "<expr2js(lhs, f)> - <expr2js(rhs, f)>";
        case and(lhs, rhs): return "<expr2js(lhs, f)> && <expr2js(rhs, f)>";
        case or(lhs, rhs): return "<expr2js(lhs, f)> || <expr2js(rhs, f)>";
        case lt(lhs, rhs): return "<expr2js(lhs, f)> \< <expr2js(rhs, f)>";
        case leq(lhs, rhs): return "<expr2js(lhs, f)> \<= <expr2js(rhs, f)>";
        case gt(lhs, rhs): return "<expr2js(lhs, f)> \> <expr2js(rhs, f)>";
        case geq(lhs, rhs): return "<expr2js(lhs, f)> \>= <expr2js(rhs, f)>";
        case equ(lhs, rhs): return "<expr2js(lhs, f)> === <expr2js(rhs, f)>";
        case neq(lhs, rhs): return "<expr2js(lhs, f)> !== <expr2js(rhs, f)>";
    }
    return "";
}

str typeAccessor(AType ty) {
    switch (ty.t) {
        case "integer": return "valueAsNumber";
        case "boolean": return "checked";
        case "string":  return "value";
    }
    return "";
}

AType getType(str id, AForm form) {
    for (/AQuestion q <- form) {
        switch (q) {
            case computedQuest(_,id2,ty,_): if (id == id2) { return ty; }
            case quest(_,id2,ty): if (id == id2) { return ty; }
        }
    }
    return qlType("string");
}
