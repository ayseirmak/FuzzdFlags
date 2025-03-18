#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define MUTATORS_COUNT 6
const char *MUTATORS[] = {"jump-mutator", "duplicate-mutator", "constant-mutator", "delete-mutator", "assignment-mutator", "expression-mutator"};

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
    return 0;
#else
#   ifdef DUPLICATE_MUTATOR
    printf(">> =DUPLICATE_MUTATOR= ");
    return 1;
#   else
#       ifdef CONSTANT_MUTATOR
            printf(">> =CONSTANT_MUTATOR= ");
            return 2;
#       else
#           ifdef DELETE_MUTATOR
                printf(">> =DELETE_MUTATOR= ");
                return 3;
#           else
#               ifdef ASSIGNMENT_MUTATOR
                    printf(">> =ASSIGNMENT_MUTATOR= ");
                    return 4;
#               else  
                    printf(">> =EXPRESSION-MUTATORS= ");
                    return 5;
#               endif // ASSIGNMENT_MUTATOR  
#           endif // DELETE_MUTATOR  
#       endif // CONSTANT_MUTATOR
#   endif // DUPLICATE_MUTATOR
#endif // JUMP_MUTATOR
}

char *pick_file(const char *dir_path) {
    DIR *dir = opendir(dir_path);
    if (!dir) return NULL;
    struct dirent *entry;
    char *files[256];
    int count = 0;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_type == DT_REG) {
            files[count] = strdup(entry->d_name);
            count++;
        }
    }
    closedir(dir);
    if (count == 0) return NULL;
    int idx = rand() % count;
    char *picked = strdup(files[idx]);
    for (int i = 0; i < count; i++) {
        free(files[i]);
    }
    return picked;
}

char *create_mutator_command(const char *tool_bin_path, const char *source_file, const char *lib_paths, const char *seed, const char *mutation) {
    static char command[1024];
    snprintf(command, sizeof(command), "timeout 5s %s/%s %s -- --no-warnings %s %s", tool_bin_path, mutation, source_file, lib_paths, seed);
    return command;
}

void execute_command(const char *command) {
    system(command);
}

int main(int argc, char *argv[]) {
    if (argc != 6) {
        fprintf(stderr, "Usage: %s <setA> <setB> <tool_build_path> <output_directory> <lib_paths_file>\n", argv[0]);
        return 1;
    }
    srand(time(NULL));

    const char *setA = argv[1];
    const char *setB = argv[2];
    const char *tool_build_path = argv[3];
    const char *output_dir = argv[4];
    const char *lib_paths_file = argv[5];

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
        char *source_file_setA = pick_file(setA);
        if (!source_file_setA) continue;
        char mutated_filename[512];
        snprintf(mutated_filename, sizeof(mutated_filename), "%s.mutated.c", source_file_setA);
        char mutated_filepath[1024];
        snprintf(mutated_filepath, sizeof(mutated_filepath), "%s/%s", setA, mutated_filename);

        char *command = create_mutator_command(tool_build_path, source_file_setA, lib_paths, seed, mutation);
        printf(">>> Running: %s", command);
        execute_command(command);

        free(source_file_setA);
        total++;
    }
    return 0;
}
