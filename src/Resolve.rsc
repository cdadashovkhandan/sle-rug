module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// Modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// Modeling use occurrences of names
alias Use = rel[loc use, str name];

// Relation def to use
alias UseDef = rel[loc use, loc def];

// The reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDefs
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

// Find all uses in the source
Use uses(AForm f) {
  result = {};

  // Only expressions can use identifiers
  for (/AExpr e := f) {
    result += get_use(e);
  }
  return result;
}

// find all definitions
Def defs(AForm f) {
  result = {};

  // Only questions can define identifiers
  for (/AQuestion q := f) {
    result += get_def(q);
  }
  return result;
}

// Fetch the definition from a question
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

// Fetch all uses from an expression
Use get_use(AExpr parent) {
  result = {};
  for (/use:ref(id) := parent) {
    result += <use.src, id.name>;
  }
  return result;
}
