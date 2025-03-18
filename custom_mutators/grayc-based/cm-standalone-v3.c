/* Save mutated files to outputdir*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>

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

char *remove_dot_c(const char *filename) {
    size_t len = strlen(filename);
    if (len > 2 && strcmp(filename + (len - 2), ".c") == 0) {
        char *res = (char *)malloc(len - 1);
        if (!res) {
            perror("malloc remove_dot_c");
            exit(1);
        }
        strncpy(res, filename, len - 2); 
        res[len - 2] = '\0';
        return res;
    } else {
        return strdup(filename);
    }
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
    int len = snprintf(command, sizeof(command),
                       "timeout 5s %s/%s %s -- --no-warnings %s %s",
                       tool_bin_path, mutation, source_file, lib_paths, seed);
    if (len < 0 || len >= (int)sizeof(command)) {
        fprintf(stderr, "Warning: command string was truncated.\n");
    }
    return command;
}


void execute_command(const char *command) {
    printf(">>> Running: %s\n", command);
    int rc = system(command);
    (void)rc;  // discard
}

/*
   copy_file(src, dst) => copies file from src to dst
   returns 0 on success, nonzero on failure
*/
int copy_file(const char *src, const char *dst) {
    FILE *fin = fopen(src, "rb");
    if (!fin) {
        perror("[!] fopen src");
        return 1;
    }
    FILE *fout = fopen(dst, "wb");
    if (!fout) {
        perror("[!] fopen dst");
        fclose(fin);
        return 1;
    }

    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), fin)) > 0) {
        fwrite(buf, 1, n, fout);
    }
    fclose(fin);
    fclose(fout);
    return 0;
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

        char *file_no_ext = remove_dot_c(filename_setA);

        char oldpath[1024];
        snprintf(oldpath, sizeof(oldpath),
                 "%s/%s.mutated.c", setA, file_no_ext);
        printf("[DEBUG] Checking for mutated file: %s\n", oldpath);

        char newpath[1024];
        snprintf(newpath, sizeof(newpath),
                 "%s/%s.mutated.c", output_dir, file_no_ext);
        printf("[DEBUG] Where we plan to copy => %s\n", newpath);

        if (access(oldpath, F_OK) == 0) {
            if (copy_file(oldpath, newpath) != 0) {
                fprintf(stderr, "[!] Could not copy mutated file from '%s' => '%s'\n",
                        oldpath, newpath);
                failed++;
            } else {
                printf("[+] Copied mutated file => %s\n", newpath);
            }
        }

        free(file_no_ext);
        free(filename_setA);
        total++;
    }

    return 0;
}
/* ./cm-standalone-jm.o /users/user42/setA /users/user42/copy_1/llvm-csmith-1/llvm-fuzzer-build/bin/ /users/user42/outpt*/
