module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDefs
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  result = {};
  for (/AExpr e := f) {
    result += get_use(e);
  }
  return result;
}

Def defs(AForm f) {
  result = {};
  for (/AQuestion q := f) {
    result += get_def(q);
  }
  return result;
}

Def get_def(parent) {
  result = {};
  for (/q:computedQuest(_, id, _, _) := parent) {
    result += <id, q.src>;
  }
  for (/q:quest(_,id,_) := parent) {
    result += <id, q.src>;
  }
  return result;
}

Use get_use(AExpr parent) {
  result = {};
  for (/use:ref(id) := parent) {
    result += <use.src, id.name>;
  }
  return result;
}

// (Uses, Id) o (Id, Def) = (Uses, Def)
// 
// Uses := Exprs
// Def := Questions
// 
// Q: How do we find things recursively? 
