#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static const char *MUTATORS[] = {
    "jump-mutator", 
    "duplicate-mutator", 
    "constant-mutator", 
    "delete-mutator", 
    "assignment-mutator", 
    "expression-mutator"
};

int random_with_N_digits(int n) {
    int range_start = 1;
    for (int i = 1; i < n; i++) {
        range_start *= 10;
    }
    int range_end = range_start * 10 - 1;
    return range_start + rand() % (range_end - range_start + 1);
}

const char *pick_mutation() {
#ifdef JUMP_MUTATOR
    printf(">> =JUMP_MUTATOR= ");
    return MUTATORS[0];
#elif defined(DUPLICATE_MUTATOR)
    printf(">> =DUPLICATE_MUTATOR= ");
    return MUTATORS[1];
#elif defined(CONSTANT_MUTATOR)
    printf(">> =CONSTANT_MUTATOR= ");
    return MUTATORS[2];
#elif defined(DELETE_MUTATOR)
    printf(">> =DELETE_MUTATOR= ");
    return MUTATORS[3];
#elif defined(ASSIGNMENT_MUTATOR)
    printf(">> =ASSIGNMENT_MUTATOR= ");
    return MUTATORS[4];
#else
    printf(">> =EXPRESSION_MUTATOR= ");
    return MUTATORS[5];
#endif
}

char *pick_file(const char *dir_path) {
    DIR *dir = opendir(dir_path);
    if (!dir) {
        fprintf(stderr, "[!] Could not open directory: %s\n", dir_path);
        return NULL;
    }

    struct dirent *entry;
    char *files[256];
    int count = 0;

    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_type == DT_REG) {
            files[count] = strdup(entry->d_name);
            count++;
            if (count >= 256) break; 
        }
    }
    closedir(dir);

    if (count == 0) {
        return NULL;
    }

    int idx = rand() % count;
    char *picked = strdup(files[idx]);

    for (int i = 0; i < count; i++) {
        free(files[i]);
    }
    return picked;
}

/*
   create_mutator_command():
  "timeout 5s <tool_build_path>/<mutation> <input_file_path> -- --no-warnings <lib_paths> <seed>"
*/
char *create_mutator_command(const char *tool_bin_path,
                             const char *source_file,
                             const char *lib_paths,
                             const char *seed,
                             const char *mutation)
{
    static char command[4096];
    snprintf(command, sizeof(command),
             "timeout 5s %s/%s %s -- --no-warnings %s %s",
             tool_bin_path, mutation, source_file, lib_paths, seed);
    return command;
}


void execute_command(const char *command) {
    printf(">>> Running: %s\n", command);
    int rc = system(command);
    (void)rc;  // discard
}

int main(int argc, char *argv[]) {
    
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <setA> <tool_build_path> <output_directory>\n", argv[0]);
        return 1;
    }

    srand((unsigned)time(NULL));

    const char *setA             = argv[1];
    const char *tool_build_path  = argv[2];
    const char *output_dir       = argv[3]; 

    char lib_paths[512] = "-I/usr/include";

    char seed[16];
    snprintf(seed, sizeof(seed), "%d", random_with_N_digits(6));

    mkdir(output_dir, 0777);

    time_t start_time = time(NULL);
    int period_of_time = 60;  
    int total = 0;
    int failed = 0;

    while (1) {
        if (time(NULL) > start_time + period_of_time) {
            printf("Ran job for: %d sec\n", period_of_time);
            printf("Processed files: %d\n", total);
            printf("Compilation failed files: %d\n", failed);
            return 0;
        }

        const char *mutation = pick_mutation();

        char *filename_setA = pick_file(setA);
        if (!filename_setA) {
            continue;
        }

        static char input_file_path[1024];
        snprintf(input_file_path, sizeof(input_file_path),
                 "%s/%s", setA, filename_setA);

        char *cmd = create_mutator_command(
                        tool_build_path,
                        input_file_path,  
                        lib_paths,
                        seed,
                        mutation
                    );

        execute_command(cmd);
        free(filename_setA);
        total++;
    }

    return 0;
}
/* ./cm-standalone-jm.o /users/user42/setA /users/user42/copy_1/llvm-csmith-1/llvm-fuzzer-build/bin/ /users/user42/outpt *\
