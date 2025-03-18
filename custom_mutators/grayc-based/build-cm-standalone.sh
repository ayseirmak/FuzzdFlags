gcc -Wall -O3 cm-standalone3.c -o cm-standalone-jm.o -D JUMP_MUTATOR
gcc -Wall -O3 cm-standalone3.c -o cm-standalone-dupm.o -D DUPLICATE_MUTATOR
gcc -Wall -O3 cm-standalone3.c -o cm-standalone-cm.o -D CONSTANT_MUTATOR
gcc -Wall -O3 cm-standalone3.c -o cm-standalone-delm.o -D DELETE_MUTATOR
gcc -Wall -O3 cm-standalone3.c -o cm-standalone-am.o -D ASSIGNMENT_MUTATOR
gcc -Wall -O3 cm-standalone3.c -o cm-standalone-em.o -D EXPRESSION_MUTATOR
