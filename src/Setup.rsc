module Setup

import Syntax;
import Resolve;
import AST;
import CST2AST;
import Check;
import Eval;
import ParseTree;
import IDE;
import IO;
import Compile;
import Transform;

set[Message] run_messages(loc src) {
    pt = parse(#Form, src);
    ast = cst2ast(pt);
    return check(ast, collect(ast), resolve(ast)[2]);
}

AForm new_ast(loc src) {
    pt = parse(#Form, src);
    ast = cst2ast(pt);
	return ast;
}

AForm normie_ast(loc src) {
    pt = parse(#Form, src);
    ast = cst2ast(pt);
	return flatten(ast);
}

void CompileFromProject(loc src) {
	ast = new_ast(src);
	compile(ast);
}

AForm testRename(loc src) {
    start[Form] pt = parse(#start[Form], src);
    ast = cst2ast(pt);
	RefGraph refs = resolve(ast);
	UseDef useDef = refs<2>;
	loc place = [use | <loc use, loc def> <- useDef][0];
	return cst2ast(rename(pt, place, "replace", useDef));
}

VEnv new_env(AForm ast) {
	return initialEnv(ast);
}

VEnv new_inp(VEnv src, AForm ast, str qId, Value val) {
	Input inp = input(qId, val);
	return eval(ast, inp, src);
}
	
VEnv new_inp(VEnv src, AForm ast, str qId, int val) 
	= new_inp(src, ast, qId, vInt(val));
	
VEnv new_inp(VEnv src, AForm ast, str qId, bool val) 
	= new_inp(src, ast, qId, vBool(val));
	
VEnv new_inp(VEnv src, AForm ast, str qId, str val) 
	= new_inp(src, ast, qId, vStr(val));

