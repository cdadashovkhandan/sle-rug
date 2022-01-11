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

HTML5Node makeQuest(AQuestion q) {
    switch(q.\type) {
      case qlType("integer"):
        return div(
            label(\for(q.id), q.name),
            input(\type("integer"), id(q.id), name(q.name))
        );
      case qlType("boolean"):
        return div(
            label(\for(q.id), q.name),
            input(\type("checkbox"), id(q.id), name(q.name))
        );
      default:
        return div(
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

//  HTML5Node htmlQuestion(AQuestion q, bool computed) {
//    return input(type("text"), id("<q.\type>"), name("<q.label>"), class("ql-enabled"))


str form2js(AForm f) {
    return "";
}
