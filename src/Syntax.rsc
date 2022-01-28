module Syntax
extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

// Root of the parse tree
start syntax Form 
  = @foldable "form" Id Block; 


// For convenience
syntax Block
  = @foldable bracket "{" Question* "}";


syntax Question
  = Str Id ":" Type
  | Str Id ":" Type "=" Expr
  | Conditional
  ; 


syntax Conditional
  = "if" "(" Expr ")" Block ("else" Block)?; 


syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Int
  | Bool
  | Str
  > right
    ( "-" Expr
    | "!" Expr )
  | bracket "(" Expr ")"
  > left
    ( Expr "*" Expr
    | Expr "/" Expr )
  > left 
    ( Expr "+" Expr
    | Expr "-" Expr )
  > non-assoc
    ( Expr "\<" Expr
    | Expr "\<=" Expr
    | Expr "\>" Expr
    | Expr "\>=" Expr )
  > non-assoc 
    ( Expr "==" Expr
    | Expr "!=" Expr )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;
  
lexical Type
  = "integer"
  | "boolean"
  | "string";  
  
// Surrounded by quotes, cannot have quotes within
lexical Str = "\"" ![\"]* "\"" ;

lexical Int = [0-9]+ ;

lexical Bool = "true" | "false" ;
