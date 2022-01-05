module Syntax
extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = @foldable "form" Id Block; 

syntax Block
  = @foldable bracket "{" Question* "}";

syntax Question
  = Str Id ":" Type
  | Str Id ":" Type "=" Expr
  | Conditional
  ; 

syntax Conditional = "if" "(" Expr ")" Block ("else" Block)?; 

syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Int
  | Bool
  | Str
  > "-" Expr
  > "!" Expr
  | bracket "(" Expr ")"
  > left
    ( Expr "*" Expr
    | Expr "/" Expr )
  > left ( Expr "+" Expr | Expr "-" Expr )
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
  
lexical Str = "\"" ![\"]* "\"" ;
lexical Int = [0-9]+ ;
lexical Bool = "true" | "false" ;
