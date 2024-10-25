grammar MiniJ;

@header {
package ch.hslu.cobau.minij;
}

// milestone 2: parser
unit
    : (globalDecl | structDecl | function)* EOF
    ;

globalDecl
    : ID ':' type ';'
    ;

structDecl
    : 'struct' ID '{' structMember* '}'
    ;

structMember
    : ID ':' type ';'
    ;

function
    : 'fun' ID '(' paramList? ')' (':' type)? functionBody SEMI?
    ;

paramList
    : param (',' param)*
    ;

param
    : OUT? ID ':' type
    ;


type
    : baseType ('[' ']')*
    ;

baseType
    : 'integer' | 'string' | 'boolean' | ID
    ;

functionBody
    : '{' (varDeclStmt | stmt)* '}'
    ;

block
    : '{' stmt* '}'
    ;

stmt
    : assignStmt
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
    : lhs '=' expr ';'
    ;

lhs
    : postfixExpr
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

functionCall
    : primaryExpr functionCallOp postfixSuffix
    ;

incDecStmt
    : lhs ('++' | '--') ';'
    | ('++' | '--') lhs ';'
    ;

expr
    : assignmentExpr
    ;

assignmentExpr
    : lhs '=' assignmentExpr
    | logicalOrExpr
    ;

logicalOrExpr
    : logicalAndExpr ('||' logicalAndExpr)*
    ;

logicalAndExpr
    : equalityExpr ('&&' equalityExpr)*
    ;

equalityExpr
    : relationalExpr (('==' | '!=') relationalExpr)*
    ;

relationalExpr
    : additiveExpr (('<' | '>' | '<=' | '>=') additiveExpr)*
    ;

additiveExpr
    : multiplicativeExpr (('+' | '-') multiplicativeExpr)*
    ;

multiplicativeExpr
    : unaryExpr (('*' | '/' | '%') unaryExpr)*
    ;

unaryExpr
    : preIncDecOperator+ unaryExpr
    | unaryOperator unaryExpr
    | postfixExpr
    | functionCall
    ;

preIncDecOperator
    : '++' | '--'
    ;

unaryOperator
    : '+' | '-' | '!'
    ;

postfixExpr
    : primaryExpr postfixSuffix
    ;

postfixSuffix
    : (memberAccessOp | arrayAccessOp)* postIncDecOperator?
    ;

postIncDecOperator
    : '++' | '--'
    ;

functionCallOp
    : '(' exprList? ')'
    ;

memberAccessOp
    : ('.' | '->') ID
    ;

arrayAccessOp
    : '[' expr ']'
    ;

primaryExpr
    : '(' expr ')'
    | NUMBER
    | STRING_LITERAL
    | 'true'
    | 'false'
    | ID
    ;

exprList
    : expr (',' expr)*
    ;

// Lexer Rules
OUT : 'out';
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
