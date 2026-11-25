%{
#include <iostream>
#include <cmath>
#include <cstring>
#include "symtable.h"

using std::cout;

int yylex(void);
int yyparse(void);
void yyerror(const char *);

SymTable tabela;

%}

%union {
    double valor;
    char nome[64];
}

%token PLACA_LIGAR PLACA_DESLIGAR TIPO_SENSOR TIPO_MEDIDA EXIBIR
%token <valor> NUMBER
%token <nome> IDENT
%type <valor> expr

%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%

programa: PLACA_LIGAR comandos PLACA_DESLIGAR {tabela.Show();}
	;

comandos: comandos comando
	|
	;

comando: TIPO_SENSOR IDENT '=' NUMBER ';' {
		if ($4 < 0 || $4 > 1023 || $4 != std::floor($4)) {
			cout << "\nERRO SEMANTICO!\nA leitura do sensor '" << $2 << "' deve ser um inteiro de 0 a 1023.\n";
			YYABORT;
		}
		Symbol s;
		s.nome = $2; s.tipo = "sensor"; s.valor = $4;
		if (!tabela.Insert($2, s)) {
			cout << "\nERRO SEMANTICO!\nIdentificador '" << $2 << "' ja declarado.\n";
			YYABORT;
		}
	}
	| TIPO_MEDIDA IDENT '=' expr ';' {
		Symbol s;
		s.nome = $2; s.tipo = "medida"; s.valor = $4;
		if (!tabela.Insert($2, s)) {
			cout << "\nERRO SEMANTICO!\nIdentificador '" << $2 << "' ja declarado.\n";
			YYABORT;
		}
	}
	| IDENT '=' expr ';' {
		Symbol* s = tabela.Find($1);
		if (s == nullptr) {
			cout << "\nERRO SEMANTICO!\nIdentificador '" << $1 << "' nao declarado.\n";
			YYABORT;
		}
		s->valor = $3;
	}
	| EXIBIR expr ';' {cout << $2 << '\n';}
	;

expr: expr '+' expr {$$ = $1 + $3;}
	|expr '-' expr {$$ = $1 - $3;}
	|expr '*' expr {$$ = $1 * $3;}
	|expr '/' expr {
		if ($3 == 0) {
			cout << "\nERRO SEMANTICO!\nDivisao por zero.\n";
			YYABORT;
		}
		$$ = $1 / $3;
	}
	|'(' expr ')' {$$ = $2;}
	|'-' expr %prec UMINUS {$$ = - $2;}
	|NUMBER
	|IDENT {
		Symbol* s = tabela.Find($1);
		if (s == nullptr) {
			cout << "\nERRO SEMANTICO!\nIdentificador '" << $1 << "' nao declarado.\n";
			YYABORT;
		}
		$$ = s->valor;
	}
	;
%%

int main()
{
	yyparse();
}

void yyerror(const char * s)
{
	cout << "\nERRO SINTATICO!\n" << s << '\n';
}
