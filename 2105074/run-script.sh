#!/bin/bash
antlr4 -Dlanguage=Cpp C2105074Lexer.g4
antlr4 -Dlanguage=Cpp C2105074Parser.g4
g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -c C2105074Lexer.cpp C2105074Parser.cpp Ctester.cpp optimizer.cpp
g++ -std=c++17 -w C2105074Lexer.o C2105074Parser.o Ctester.o -L/usr/local/lib/ -lantlr4-runtime -o Ctester.out -pthread
g++ -std=c++17 -w optimizer.o -o optimizer.out
LD_LIBRARY_PATH=/usr/local/lib ./Ctester.out $1

# Concatenate machine code files after parsing
if [ -f "output/machineCodePart2.txt" ] && [ -f "output/machineCode.txt" ]; then
    echo "Concatenating machine code files..."
    cat output/machineCodePart2.txt > output/finalMachineCode.asm
    echo "" >> output/finalMachineCode.asm
    echo ".CODE" >> output/finalMachineCode.asm
    cat output/machineCode.txt >> output/finalMachineCode.asm

    echo "" >> output/finalMachineCode.asm
    cat print.txt >> output/finalMachineCode.asm
    echo "END main" >> output/finalMachineCode.asm
    echo "Final machine code written to output/finalMachineCode.asm"
    
    # Run optimization on the final assembly code
    echo "Running code optimization..."
    ./optimizer.out
fi
