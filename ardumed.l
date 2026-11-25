%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include "ardumed.tab.h"
%}

%option noyywrap

numero [0-9]+("."[0-9]+)?
ident [a-zA-Z_][a-zA-Z0-9_]*

%%
"//".* ;
[ \t\r\n]+ ;
placa_ligar return PLACA_LIGAR;
placa_desligar return PLACA_DESLIGAR;
sensor return TIPO_SENSOR;
medida return TIPO_MEDIDA;
exibir return EXIBIR;
{numero} yylval.valor = atof(yytext); return NUMBER;
{ident} strncpy(yylval.nome, yytext, 63); yylval.nome[63] = 0; return IDENT;
[-+*/()=;] return yytext[0];
. std::cout << "\nERRO LEXICO!\nSimbolo desconhecido '" << yytext << "'\n"; exit(1);

%%
