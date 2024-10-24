grammar MiniJ;

@header {
package ch.hslu.cobau.minij;
}

// milestone 2: parser
// a string like `number : integer` should be parsable
// doesnt need a single function

unit : function*;
// function without name should fail example: fun () {}
// function can have zero or more parameters
function : 'fun' IDENTIFIER '(' parameters? ')' block;
parameters : parameter (',' parameter)*;
parameter : IDENTIFIER ':' type ';'?;
type : 'integer' | 'boolean' | 'string';
block : '{' statement* '}';
statement : assignment | ifStatement | whileStatement | returnStatement;
assignment : parameter '=' expression ';';
ifStatement : 'if' expression block ('else' block)?;
whileStatement : 'while' expression block;
returnStatement : 'return' expression ';';
expression : IDENTIFIER | IDENTIFIER '(' arguments ')' | expression ('+' | '-' | '*' | '/' | '==' | '!=' | '<' | '>' | '<=' | '>=') expression | '(' expression ')';
arguments : expression (',' expression)*;

// identifier cannot be empty
IDENTIFIER : [a-zA-Z][a-zA-Z0-9]*;
LETTER : [a-zA-Z];
DIGITS : [0-9]+;
WS : [ \t\r\n]+ -> skip;
