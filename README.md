# InfixCalculatorCompiler
Compilers project at University of Verona

It is an **infix calculator** with +, - ,*, / operations and if-then-else statement. Also, comparison operators <, >, <=, >=, ==, != are supported. They return `True` or `False` to the terminal.
Variables are the characters of the alphabet and they can only store integer values.

The compiler can also accept as input a file containing code written with the syntax of our infix calculator. The output of our compiler is a translation of the infix calculator notation into *3-address code* with C sintax. Output file written in C can be compiled with `gcc` if there are no errors in the input file.

## How to compile

```bash
yacc -d 3ac.y
lex lexer.l
gcc y.tab.c lex.yy.c -lfl
```

From Linux shell:

```bash
./a.out [inputFile]
OR
./a.out [inputFile] [outputFile.c]
```

From Windows prompt:

```bash
./a.exe [inputFile]
OR
./a.exe [inputFile] [outputFile.c]
```

If you want to run only the calculator, you can do as follow:
```bash
yacc -d infix_calc.y
lex lexer.l
gcc y.tab.c lex.yy.c -lfl
```
