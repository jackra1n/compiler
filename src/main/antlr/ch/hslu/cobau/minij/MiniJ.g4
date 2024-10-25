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

exprStmt    : expr ';';

functionCall : ID '(' exprList? ')';

exprList    : expr (',' expr)*;

expr        : expr ('&&' | '||') expr               // Logical OR/AND precedence level
            | expr ('<' | '>' | '<=' | '>=') expr   // Relational precedence level
            | expr ('==' | '!=') expr               // Equality precedence level
            | expr ('+' | '-') expr                 // Additive precedence level
            | expr ('*' | '/' | '%') expr           // Multiplicative precedence level
            | ('+' | '-' | '!') expr                // Unary prefix operators (+, -, !)
            | ('++' | '--') expr
            | expr ('++' | '--')
            | '(' expr ')'                          // Parenthesized expressions
            | functionCall
            | NUMBER
            | STRING_LITERAL
            | 'true'
            | 'false'
            | ID
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
