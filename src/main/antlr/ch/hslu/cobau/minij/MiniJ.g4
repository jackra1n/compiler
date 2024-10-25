grammar MiniJ;

@header {
package ch.hslu.cobau.minij;
}

// milestone 2: parser
unit        : globalDecl* function* EOF;

globalDecl  : ID ':' type ';';

function    : 'fun' ID '(' paramList? ')' (':' type)? block;

paramList   : param (',' param)*;

param       : ID ':' type;

type        : 'integer' | 'string' | 'boolean';

block       : '{' stmt* '}';

stmt        : varDeclStmt
            | assignStmt
            | ifStmt
            | whileStmt
            | returnStmt
            | functionCallStmt
            | exprStmt
            | block
            | ';'
            ;

varDeclStmt : ID ':' type ';';

assignStmt  : ID '=' expr ';';

ifStmt      : 'if' '(' expr ')' stmt;

whileStmt   : 'while' '(' expr ')' stmt;

returnStmt  : 'return' expr? ';';

functionCallStmt : functionCall ';';

exprStmt    : assignmentOrExpr ';';

assignmentOrExpr
            : ID '=' expr
            | expr
            ;

functionCall : ID '(' exprList? ')';

exprList    : expr (',' expr)*;

expr        : ('+' | '-') expr                // Allows + or - before an expression
            | expr ('&&' | '||') expr
            | expr ('<' | '>' | '<=' | '>=') expr
            | expr ('+' | '-') expr
            | expr ('*' | '/' | '%') expr
            | ('++' | '--') expr
            | expr ('++' | '--')
            | '(' expr ')'
            | ID
            | NUMBER
            | STRING_LITERAL
            ;

ID          : [a-zA-Z][a-zA-Z0-9]*;
NUMBER      : [0-9]+;
STRING_LITERAL : '"' .*? '"';
WS          : [ \t\r\n]+ -> skip;
COMMENT     : '//' ~[\r\n]* -> skip;
LPAREN      : '(';
RPAREN      : ')';
LBRACE      : '{';
RBRACE      : '}';
SEMI        : ';';
COLON       : ':';
COMMA       : ',';
ASSIGN      : '=';
