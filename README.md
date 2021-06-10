# InfixCalculatorCompiler
Compilers project at University of Verona

## How to run the compiler
yacc -d 3ac.y
lex lexer.l
gcc lex.yy.c y.tab.c -lfl
./a.out text.txt

## How to run infix calculator interpreter
yacc -d infix_calculator.y
lex lexer.l
gcc lex.yy.c y.tab.c -lfl
./a.out
