module Setup

import Syntax;
import Resolve;
import AST;
import CST2AST;
import Check;
import Eval;
import ParseTree;
import IDE;

set[Message] run_messages(loc src) {
    pt = parse(#Form, src);
    ast = cst2ast(pt);
    return check(ast, collect(ast), resolve(ast)[2]);
}

VEnv run_input(loc src, str qId, int val) {
    pt = parse(#Form, src);
    f = cst2ast(pt);
	VEnv venv = initialEnv(ast);
	Input inp = input(qId, vInt(val));
	return eval(f, inp, venv);
}

VEnv run_input(loc src, str qId, bool val) {
    pt = parse(#Form, src);
    f = cst2ast(pt);
	VEnv venv = initialEnv(f);
	Input inp = input(qId, vBool(val));
	return eval(f, inp, venv);
}

VEnv run_input(loc src, str qId, str val) {
    pt = parse(#Form, src);
    f = cst2ast(pt);
	VEnv venv = initialEnv(f);
	Input inp = input(qId, vStr(val));
	return eval(f, inp, venv);
}
