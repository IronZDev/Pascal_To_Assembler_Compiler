objects = main.o emitter.o error.o init.o lexer.o \
	parser.o symbol.o

comp : $(objects)
	g++ -o comp $(objects)
	
main.o : main.cpp global.hpp
	g++ -c main.cpp
	
emitter.o : emitter.cpp global.hpp parser.hpp
	g++ -c emitter.cpp
	
error.o : error.cpp global.hpp
	g++ -c error.cpp
	
init.o : init.cpp global.hpp parser.hpp
	g++ -c init.cpp
	
lexer.o : lexer.cpp global.hpp parser.hpp
	g++ -c lexer.cpp -o lexer.o
	
lexer.cpp : lexer.l
	flex -o lexer.cpp lexer.l 
	
parser.o : parser.cpp global.hpp
	g++ -c parser.cpp
	
parser.cpp parser.hpp : parser.y
	bison -o parser.cpp -d parser.y
	
symbol.o : symbol.cpp global.hpp
	cc -c symbol.cpp
	
clean : 
	rm comp lexer.cpp parser.cpp parser.hpp $(objects)
