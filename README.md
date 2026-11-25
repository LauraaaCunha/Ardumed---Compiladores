# ArduMed

Linguagem de programação própria para **descrever leituras de sensores do Arduino e converter essas leituras em unidades úteis** (volts, graus Celsius, graus Fahrenheit). O ArduMed é um **interpretador** no estilo da calculadora vista em aula: as ações semânticas calculam os valores na hora e imprimem o resultado, sem gerar código intermediário.

Trabalho da disciplina de **Compiladores** - IFRS Campus Ibirubá - Prof. Gabriel dos Santos.

**Autoria:** Laura 

---

## Ideia da linguagem

O Arduino Uno não mede tensão diretamente: o conversor analógico-digital (ADC) entrega um número inteiro de **0 a 1023**, onde 0 corresponde a 0 V e 1023 corresponde a 5 V. O sensor de temperatura **LM35** produz **10 mV por grau Celsius**. Por isso, para chegar à temperatura, o programa segue esta cadeia:

```
leitura (0 a 1023)  →  volts  →  graus Celsius  →  (opcional) graus Fahrenheit
```

O ArduMed existe para escrever essa cadeia de forma direta, guardando cada etapa em uma variável.

---

## Arquivos do projeto

| Arquivo | Função |
|---|---|
| `ardumed.l` | Analisador léxico (Flex): reconhece palavras reservadas, números, identificadores e símbolos |
| `ardumed.y` | Analisador sintático e ações semânticas (Bison): gramática, cálculos e mensagens de erro |
| `symtable.h` / `symtable.cpp` | Tabela de símbolos (`SymTable`), usada pelo `.y` |
| `codigo_para_executar.txt` | Programa de exemplo escrito em ArduMed |
| `ardumed.tab.c` / `ardumed.tab.h` / `ardumed.output` | Gerados pelo Bison |
| `ardumed.lex.c` | Gerado pelo Flex |

---

## Requisitos

- Windows com PowerShell
- `win_bison` (testado com 3.8.2) e `win_flex` (testado com 2.6.4)
- `g++` com suporte a C++17

---

## Como compilar e executar

Abra o PowerShell **na pasta do projeto** e rode, nesta ordem:

```powershell
win_bison -v -d -o ardumed.tab.c "ardumed.y"
win_flex -o ardumed.lex.c ardumed.l
g++ ardumed.tab.c ardumed.lex.c symtable.cpp -o ardumed_flex
Get-Content codigo_para_executar.txt | ./ardumed_flex
```

O que cada comando faz:

1. **`win_bison -v -d -o ardumed.tab.c "ardumed.y"`** — gera o analisador sintático (`ardumed.tab.c`), o cabeçalho com os tokens (`ardumed.tab.h`, por causa do `-d`) e o relatório do autômato (`ardumed.output`, por causa do `-v`).
2. **`win_flex -o ardumed.lex.c ardumed.l`** — gera o analisador léxico (`ardumed.lex.c`).
3. **`g++ ardumed.tab.c ardumed.lex.c symtable.cpp -o ardumed_flex`** — compila tudo junto e cria o executável `ardumed_flex.exe`.
4. **`Get-Content codigo_para_executar.txt | ./ardumed_flex`** — envia o programa ArduMed para a entrada padrão do interpretador.

---

## A linguagem

### Estrutura obrigatória

Todo programa começa com `placa_ligar` e termina com `placa_desligar`. Os comandos ficam entre essas duas palavras. Ao chegar em `placa_desligar`, o interpretador imprime a tabela de símbolos.

```
placa_ligar
  ... comandos ...
placa_desligar
```

### Palavras reservadas

| Palavra | Significado |
|---|---|
| `placa_ligar` | Início do programa |
| `placa_desligar` | Fim do programa |
| `sensor` | Declara uma leitura bruta do ADC (inteiro de 0 a 1023) |
| `medida` | Declara um valor decimal calculado (volts, Celsius etc.) |
| `exibir` | Imprime o valor de uma expressão |

### Comandos

Todo comando termina com `;`.

| Comando | Exemplo | O que faz |
|---|---|---|
| Declarar sensor | `sensor leitura = 61;` | Guarda uma leitura inteira de 0 a 1023 |
| Declarar medida | `medida volts = leitura * 5.0 / 1023;` | Guarda o resultado de uma expressão |
| Atribuir | `celsius = celsius - 1.5;` | Muda o valor de uma variável já declarada |
| Exibir | `exibir celsius;` | Imprime o valor da expressão |

### Expressões

Aceitam números (inteiros ou decimais com ponto, como `5.0`), identificadores já declarados, parênteses e as operações `+`, `-`, `*`, `/` e o menos unário (`-x`).

Precedência, da maior para a menor:

1. menos unário (`-x`)
2. `*` e `/` (associam da esquerda para a direita)
3. `+` e `-` (associam da esquerda para a direita)

### Identificadores e comentários

- Identificadores: começam com letra ou `_`, seguidos de letras, dígitos ou `_`.
- Comentários: `//` até o fim da linha.
- Espaços, tabulações e quebras de linha são ignorados.

---

## Gramática

```
programa  → PLACA_LIGAR comandos PLACA_DESLIGAR

comandos  → comandos comando
          | ε

comando   → TIPO_SENSOR IDENT '=' NUMBER ';'
          | TIPO_MEDIDA IDENT '=' expr ';'
          | IDENT '=' expr ';'
          | EXIBIR expr ';'

expr      → expr '+' expr
          | expr '-' expr
          | expr '*' expr
          | expr '/' expr
          | '(' expr ')'
          | '-' expr
          | NUMBER
          | IDENT
```

**Terminais:** `PLACA_LIGAR`, `PLACA_DESLIGAR`, `TIPO_SENSOR`, `TIPO_MEDIDA`, `EXIBIR`, `NUMBER`, `IDENT`, `'='`, `';'`, `'+'`, `'-'`, `'*'`, `'/'`, `'('`, `')'`.

**Não terminais:** `programa`, `comandos`, `comando`, `expr`.

---

## Exemplo

Conteúdo de `codigo_para_executar.txt`:

```
placa_ligar
  sensor leitura = 61;
  medida referencia = 5.0;
  medida volts = leitura * referencia / 1023;
  medida celsius = volts * 100;
  medida fahrenheit = celsius * 9 / 5 + 32;
  exibir volts;
  exibir celsius;
  exibir fahrenheit;
  celsius = (celsius - 1.5) * 2;
  exibir celsius;
placa_desligar
```

Saída esperada:

```
0.298143
29.8143
85.6657
56.6285

TABELA DE SIMBOLOS
---------------------------------------------
NOME           TIPO           VALOR
---------------------------------------------
fahrenheit     medida         85.6657
celsius        medida         56.6285
volts          medida         0.298143
referencia     medida         5
leitura        sensor         61
---------------------------------------------
```

> A ordem das linhas da tabela pode variar de um computador para outro, porque ela é guardada em um `unordered_map`.

### Como cada linha é calculada

| Linha | Conta | Resultado |
|---|---|---|
| `volts` | 61 × 5,0 / 1023 | 0,298143 V |
| `celsius` | volts × 100 (o LM35 dá 10 mV por °C, então 1 V = 100 °C) | 29,8143 °C |
| `fahrenheit` | celsius × 9 / 5 + 32 | 85,6657 °F |
| `celsius` (reatribuída) | (29,8143 − 1,5) × 2 | 56,6285 |

Sobre a conversão para Fahrenheit: o fator **9/5** existe porque entre o congelamento e a fervura da água o Celsius tem 100 divisões e o Fahrenheit tem 180; o **+32** existe porque a água congela em 0 °C, que equivale a 32 °F. Essa linha serve para mostrar conversão de unidade e o reaproveitamento de uma variável calculada antes.

---

## Tabela de símbolos

Implementada em `symtable.h` / `symtable.cpp` com `unordered_map<string, Symbol>`.

Cada `Symbol` guarda:

| Campo | Tipo | Conteúdo |
|---|---|---|
| `nome` | `string` | Nome da variável |
| `tipo` | `string` | `"sensor"` ou `"medida"` |
| `valor` | `double` | Valor atual |

Operações:

- `Insert(nome, simbolo)` — insere; devolve `false` se o nome já existir.
- `Find(nome)` — devolve um ponteiro para o símbolo, ou `nullptr` se não existir.
- `Show()` — imprime a tabela (chamada ao chegar em `placa_desligar`).

---

## Tratamento de erros

Ao encontrar um erro, o interpretador imprime a mensagem e para (nos erros semânticos, com `YYABORT`).

| Tipo | Quando acontece | Mensagem |
|---|---|---|
| Léxico | Caractere que não pertence à linguagem (ex.: `@`) | `ERRO LEXICO! Simbolo desconhecido '@'` |
| Sintático | Programa fora da gramática (ex.: falta `;`) | `ERRO SINTATICO! syntax error` |
| Semântico | Sensor fora de 0–1023 ou não inteiro | `ERRO SEMANTICO! A leitura do sensor 's' deve ser um inteiro de 0 a 1023.` |
| Semântico | Declarar um nome que já existe | `ERRO SEMANTICO! Identificador 'a' ja declarado.` |
| Semântico | Usar ou atribuir um nome não declarado | `ERRO SEMANTICO! Identificador 'x' nao declarado.` |
| Semântico | Divisão por zero | `ERRO SEMANTICO! Divisao por zero.` |

---

## Limitações conhecidas

- A faixa de 0 a 1023 só é verificada **na declaração** do sensor. Uma atribuição posterior (`leitura = 5000;`) é aceita.
- A saída usa a precisão padrão do `cout` (6 algarismos significativos).
- Não há funções nem estruturas de decisão (eram opcionais no enunciado).
