pathAFL=$1/include/
gcc -Wall -O3 -I $pathAFL cm.c -o cm-jm.so -D JUMP_MUTATOR
gcc -Wall -O3 -I $pathAFL cm.c -o cm-dupm.so -D DUPLICATE_MUTATOR
gcc -Wall -O3 -I $pathAFL cm.c -o cm-cm.so -D CONSTANT_MUTATOR
gcc -Wall -O3 -I $pathAFL cm.c -o cm-delm.so -D DELETE_MUTATOR
gcc -Wall -O3 -I $pathAFL cm.c -o cm-am.so -D ASSIGNMENT_MUTATOR
gcc -Wall -O3 -I $pathAFL cm.c -o cm-em.so -D EXPRESSION_MUTATOR
