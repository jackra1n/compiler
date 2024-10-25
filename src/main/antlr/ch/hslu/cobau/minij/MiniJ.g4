grammar MiniJ;

@header {
package ch.hslu.cobau.minij;
}

// milestone 2: parser
unit
    : globalDecl* function* EOF
    ;

globalDecl
    : ID ':' type ';'
    ;

function
    : 'fun' ID '(' paramList? ')' (':' type)? block SEMI?
    ;

paramList
    : param (',' param)*
    ;

param
    : ID ':' type
    ;

type
    : 'integer' | 'string' | 'boolean'
    ;

block
    : '{' stmt* '}'
    ;

stmt
    : varDeclStmt
    | assignStmt
    | ifStmt
    | whileStmt
    | returnStmt
    | functionCallStmt
    | incDecStmt
    | block
    | ';'
    ;

varDeclStmt
    : ID ':' type ';'
    ;

assignStmt
    : ID '=' expr ';'
    ;

ifStmt
    : 'if' '(' expr ')' stmt ('else' stmt)?
    ;

whileStmt
    : 'while' '(' expr ')' stmt
    ;

returnStmt
    : 'return' expr? ';'
    ;

functionCallStmt
    : functionCall ';'
    ;

incDecStmt
    : incDecExpr ';'
    ;

functionCall
    : ID '(' exprList? ')'
    ;

exprList
    : expr (',' expr)*
    ;

expr
    : logicalOrExpr
    ;

logicalOrExpr
    : logicalOrExpr '||' logicalAndExpr
    | logicalAndExpr
    ;

logicalAndExpr
    : logicalAndExpr '&&' equalityExpr
    | equalityExpr
    ;

equalityExpr
    : equalityExpr ('==' | '!=') relationalExpr
    | relationalExpr
    ;

relationalExpr
    : relationalExpr ('<' | '>' | '<=' | '>=') additiveExpr
    | additiveExpr
    ;

additiveExpr
    : additiveExpr ('+' | '-') multiplicativeExpr
    | multiplicativeExpr
    ;

multiplicativeExpr
    : multiplicativeExpr ('*' | '/' | '%') unaryExpr
    | unaryExpr
    ;

unaryExpr
    : preIncDecExpr
    | unaryOperator unaryExpr
    | postfixExpr
    ;

preIncDecExpr
    : preIncDecOperator+ unaryExpr
    ;

preIncDecOperator
    : '++' | '--'
    ;

unaryOperator
    : '+' | '-'
    | '!'
    ;

postfixExpr
    : primaryExpr postIncDecOperator?
    ;

postIncDecOperator
    : '++' | '--'
    ;

primaryExpr
    : '(' expr ')'
    | functionCall
    | NUMBER
    | STRING_LITERAL
    | 'true'
    | 'false'
    | ID
    ;

incDecExpr
    : ('++' | '--') ID
    | ID ('++' | '--')
    ;

// Lexer Rules
ID : [a-zA-Z_$][a-zA-Z0-9_$]*;
NUMBER: [0-9]+;
STRING_LITERAL: '"' .*? '"';
WS: [ \t\r\n]+ -> skip;

// Keywords
LPAREN: '(';
RPAREN: ')';
LBRACE: '{';
RBRACE: '}';
SEMI: ';';
COLON: ':';
COMMA: ',';
ASSIGN: '=';
MULTI_LINE_COMMENT: '/*' .*? '*/' -> skip;
SINGLE_LINE_COMMENT: '//' ~[\r\n]* -> skip;
