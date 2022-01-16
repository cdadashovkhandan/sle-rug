module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
    writeFile(f.src[extension="js"].top, form2js(f));
    writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
    list[value] questions = [];

    for (/AQuestion q <- f) {
        switch (q) {
            case quest(_,_,_):
                questions += makeQuest(q);
            case computedQuest(_,_,_,_):
                questions += makeComputedQuest(q);
        }
    }

    return html(
            head(
                title("something"),
                script("js-path")  // FIXME
            ),
            body(
                form(
                    id(f.name),
                    questions
                )
            )
        );
}

HTML5Node makeQuestsFromList(list[Aquestion] qs) {
    for (/AQuestion q <- q) { //TODO: is this right?
        switch (q) {
            case quest(_,_,_):
                questions += makeQuest(q);
            case computedQuest(_,_,_,_):
                questions += makeComputedQuest(q);
        }
    }
}

HTML5Node makeQuest(AQuestion q) {
    switch(q.\type) {
      case qlType("integer"):
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),
            input(\type("integer"), id(q.id), name(q.name))
        );
      case qlType("boolean"):
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),
            input(\type("checkbox"), id(q.id), name(q.name))
        );
      default:
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),
            input(\type("text"), id(q.id), name(q.name))
        );
    }
}

HTML5Node makeComputedQuest(AQuestion cq) {
    switch(cq.\type) {
      case qlType("integer"):
        return div(
            label(\for(cq.id), cq.name),
            input(\type("integer"), id(cq.id), name(cq.name), class("ql-computed"))
        );
      case qlType("boolean"):
        return div(
            label(\for(cq.id), cq.name),
            input(\type("checkbox"), id(cq.id), name(cq.name), class("ql-computed"))
        );
      default:
        return div(
            label(\for(cq.id), cq.name),
            input(\type("text"), id(cq.id), name(cq.name), class("ql-computed"))
        );
    }
}

//IF THEN ELSE BUILDER, I'M SORRY MIGUEL
HTML5Node makeIfElse(AQuestion q) {
    switch(q) {
      case ifThen(g, qs):
        return div(
            id(g.src)
            class("ql-if-else")
            div(
                class("ql-if"),
                makeQuestsFromList(qs)
            )
            div(class(ql-else))
        );
      case ifThenElse(g, iqs, eqs):
        return div(
            id(g.src)
            class("ql-if-else")
            div(
                class("ql-if"),
                makeQuestsFromList(iqqs)
            )
            div(
                class("ql-else"),
                makeQuestsFromList(eqs)
            )
        );
    }
}

// NOTE: THIS CAN BE REMOVED
//  HTML5Node htmlQuestion(AQuestion q, bool computed) {
//    return input(type("text"), id("<q.\type>"), name("<q.label>"), class("ql-enabled"))


str form2js(AForm f) {
    js_str = "";
    for (AQuestion q in f) {
        js_str += quest2js(q, f);
    }
    return js_str;
}

str quest2js(AQuestion f, AForm f) {
    switch (q) {
        computedQuest(_,id,ty,expr): {
            str accessor = typeAccessor(ty);
            return  "$('#<f.name>').on('formUpdated', function (event) {
                    '   $('#<id>')[0].<accessor> = <expr2js(expr, f)>;
                    '})";
        }
        quest(_,id,ty): {
            str accessor = typeAccessor(ty);
            return  "$('#<id>').on('change', function (event) {
                    '   $('#<f.name>').trigger('formUpdated');
                    '})";
        }
        ifThen(guard,iqs): {
            source = guard.src //god I dohn't fucking rknow I think it' right?
            output = "$('#<f.name>').on('formUpdated', function (event) {
                    '   if (<expr2js(guard, f)>) {
                    '       $('<source>').addClass('true');
                    '   }
                    '})";
            // build js code for every question inside the if
            for (/AQuestion iq <- iqs) {
                output + "
                '" + quest2js(iq) // holy fuck this is hideous
                // but a newline between each q wouldn't hurt right?
            }
            return output
        }
        ifThenElse(guard,iqs,eqs):
            source = guard.src //god I dohn't fucking rknow I think it' right?
            output = "$('#<f.name>').on('formUpdated', function (event) {
                    '   if (<expr2js(guard, f)>) {
                    '       $('<source>').addClass('true');
                    '   } else {
                    '       $('<source>').removeClass('true');
                    '   }
                    '})";
            // build js code for every question inside the if AND the else
            // I don't think their location matters anyway
            for (/AQuestion iq <- iqs + eqs) { // concat the two lists
                output + "
                '" + quest2js(iq) // holy fuck this is hideous
                // but a newline between each q wouldn't hurt right?
            }
    }
}

str expr2js(AExpr e, AForm f) {
    switch (e) {
        case ref(id(name, src = loc u)): {
            AType ty = getType(name, f);
            str accessor = typeAccessor(ty);
            return "$('#<name>')[0].<accessor>";
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
        case gt(lhs, rhs): return "<expr2js(lhs, f)> > <expr2js(rhs, f)>";
        case geq(lhs, rhs): return "<expr2js(lhs, f)> >= <expr2js(rhs, f)>";
        case equ(lhs, rhs): return "<expr2js(lhs, f)> === <expr2js(rhs, f)>";
        case neq(lhs, rhs): return "<expr2js(lhs, f)> !== <expr2js(rhs, f)>";
    }
}

str typeAccessor(AType ty) {
    switch (ty.t) {
        case "integer": return "valueAsNumber";
        case "boolean": return "value";
        case "string":  return "checked";
    }
}

str getType(str id, AForm form) {
    for (/AQuestion q <- f) {
        switch (q) {
            computedQuest(_,id2,ty,_): if (id == id2) { return ty; }
            quest(_,id2,ty): if (id == id2) { return ty; }
        }
    }
    return "string";
}
