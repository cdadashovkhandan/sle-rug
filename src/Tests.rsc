module Tests

import ParseTree;

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Compile;
import Check;
import Transform;
import Eval;

import IO;

/*
*    This is a monster file to help
*    you run everything right off the bat.
*/

// Test Syntax.rsc
start[Form] test_parse(loc source_file)
    = parse(#start[Form], source_file);

// Test AST.rsc && CST2AST.rsc
AForm test_ast(loc source_file)
    = cst2ast(parse(#start[Form], source_file));

// Test Resolve.rsc
RefGraph test_resolve(loc source_file)
    = resolve(test_ast(source_file));

// Test Eval.rsc
VEnv test_venv(loc source_file)
	= initialEnv(test_ast(source_file));

VEnv test_eval(loc source_file, VEnv venv, str id, value val) {
	Value v_val;
	println("Val: <typeOf(val)>");
	if (typeOf(val) == typeOf(0)) {
		v_val = vInt(val);
	} else if (typeOf(val) == typeOf(true)) {
		println("Val: <val>");
		v_val = vBool(val);
	} else if (typeOf(val) == typeOf("Sorry")) {
		println("Val: <val>");
		v_val = vStr(val);
	} else {
		throw "Wrong type";
	}
	AForm form = test_ast(source_file);
	VEnv venv = initialEnv(form);
    Input inp = input(id, v_val);
	return eval(form, inp, venv);
}

// Test Check.rsc
set[Message] test_check(loc source_file) {
    AForm form = test_ast(source_file);
    return check(form, collect(form), resolve(form)[2]);
}

// Test Compile.rsc
void test_compile(loc source_file)
	= compile(test_ast(source_file));

// Test Transform.rsc
AForm test_flatten(loc source_file)
    = flatten(test_ast(source_file));

AForm test_rename(loc source_file, loc location, str new_name) {
    pt = test_parse(source_file);
    ast = test_ast(source_file);
    return cst2ast(rename(pt, location, new_name, resolve(ast)[2]));
}
