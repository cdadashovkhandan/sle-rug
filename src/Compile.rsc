module Compile

import AST;
import Resolve;
import IO;
import List; //TODO: REMOVE LATER
import String;
import lang::html5::DOM; // see standard library
import CompileJs;

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

    list[HTML5Node] questions = makeQuestsFromList([ q | AQuestion q <- f.questions ]);
    
    return html(
            head(
                title("something"),
                script(src("https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js")),
                link(\rel("stylesheet"), href("main.css"))
            ),
            body(
                form(
                    id(f.name),
                    kidsToString(questions)
                ),
                script(src(f.src[extension="js"].path))
            )
        );
}

list[HTML5Node] makeQuestsFromList(list[AQuestion] qs) {
    list[HTML5Node] questions = [];
    for (AQuestion q <- qs) { 
        switch (q) {
            case quest(_,_,_):
                questions += makeQuest(q);
            case computedQuest(_,_,_,_):
                questions += makeComputedQuest(q);
            case ifThen(_,_):
                questions += makeIfElse(q);
            case ifThenElse(_,_,_):
                questions += makeIfElse(q);
        }
    }
    return questions;
}

str trimQuotes(str inp) {
    return replaceAll(inp, "\"", "");
}

HTML5Node makeQuest(AQuestion q) {
    switch(q.\type) {
      case qlType("integer"):
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),

            input(\type("number"), id(q.id), name(trimQuotes(q.name)))
        );
      case qlType("boolean"):
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),
            input(\type("checkbox"), id(q.id), name(trimQuotes(q.name)))
        );
      default:
        return div(
            class("ql-question-wrapper"),
            label(\for(q.id), q.name),
            input(\type("text"), id(q.id), name(trimQuotes(q.name)))
        );
    }
}

HTML5Node makeComputedQuest(AQuestion cq) {
    switch(cq.\type) {
      case qlType("integer"):
        return div(
            class("ql-question-wrapper"),
            label(\for(cq.id), cq.name),
            input(\type("number"), id(cq.id), name(trimQuotes(cq.name)), class("ql-computed"), readonly("readonly"))
        );
      case qlType("boolean"):
        return div(
            class("ql-question-wrapper"),
            label(\for(cq.id), cq.name),
            input(\type("checkbox"), id(cq.id), name(trimQuotes(cq.name)), class("ql-computed"), readonly("readonly"), onclick("return false;"))
        );
      default:
        return div(
            class("ql-question-wrapper"),
            label(\for(cq.id), cq.name),
            input(\type("text"), id(cq.id), name(trimQuotes(cq.name)), class("ql-computed"), readonly("readonly"))
        );
    }
}

//IF THEN ELSE BUILDER, I'M SORRY MIGUEL
HTML5Node makeIfElse(AQuestion q) {
    switch(q) {
      case ifThen(_, qs):
        return div(
            id(cleanLoc(q.src)),
            class("ql-if-else"),
            div(
                class("ql-if"),
                kidsToString(makeQuestsFromList(qs))
            ),
            div(class("ql-else"))
        );
      case ifThenElse(_, iqs, eqs):
        return div(
            id(cleanLoc(q.src)),
            class("ql-if-else"),
            div(
                class("ql-if"),
                kidsToString(makeQuestsFromList(iqs))
            ),
            div(
                class("ql-else"),
                kidsToString(makeQuestsFromList(eqs))
            )
        );
    }
    return div();
}
