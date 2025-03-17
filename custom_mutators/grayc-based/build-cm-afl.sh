pathAFL=$1/include/
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-jm.o -D JUMP_MUTATOR
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-dupm.o -D DUPLICATE_MUTATOR
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-cm.o -D CONSTANT_MUTATOR
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-delm.o -D DELETE_MUTATOR
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-am.o -D ASSIGNMENT_MUTATOR
gcc -Wall -O3 -I $pathAFL cm-standalone.c -o cm-em.o -D EXPRESSION_MUTATOR
