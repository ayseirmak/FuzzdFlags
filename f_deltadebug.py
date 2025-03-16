#!/usr/bin/env python3
#./f_deltadebug.py /opt/llvm-19/bin/clang  /users/user42/llvmSS-reindex-cfiles/test_1016.c '1'
import sys
import subprocess
import itertools
import os

def main():
    """
    Usage:
      f_deltadebug.py <clang_path> <test_c_file> <combination_sizes> <flags...>

    Example:
      ./f_deltadebug.py /opt/llvm-19/bin/clang /path/to/test.c "1,2" -O1 -O2 -fno-strict-return ...
    
    <clang_path>        : Full path to the clang binary
    <test_c_file>       : Path to the test C source file
    <combination_sizes> : Comma-separated list of combination sizes (e.g. "1,2,3")
    <flags...>          : All possible flags, each as a separate argument
    
    This script:
      1) Removes duplicate flags.
      2) For each combination size specified, tries all subsets of that size.
      3) Compiles and runs the test file with those flags plus some constant flags.
      4) If a crash occurs (typically return code higher than 128), it logs the result
         (return code and flags) to a file named "<base_of_test_file>_<combo_size>.log".
    """

    if len(sys.argv) < 5:
        print(f"Usage: {sys.argv[0]} <clang_path> <test_c_file> <combination_sizes> <flags...>")
        print("  e.g. './f_deltadebug.py /opt/llvm-19/bin/clang mytest.c \"1,2\" -O1 -O2 -fno-strict-return'")
        sys.exit(1)
    
    # 1) Check that INCLUDES_DIR env is defined
    INCLUDES_DIR = os.environ.get("INCLUDES_DIR")
    if not INCLUDES_DIR:
        print("[!]Please set INCLUDES_DIR environment variable, e.g.:")
        print('   export INCLUDES_DIR="/users/user42/llvmSS-include"')
        sys.exit(1)
    
    clang_path = sys.argv[1]
    test_c_path = sys.argv[2]
    combination_sizes_str = sys.argv[3]  # e.g. "1,2,3"
    
    # Parse combination sizes (e.g. "1,2,3" -> [1,2,3])
    try:
        combination_sizes = [int(x.strip()) for x in combination_sizes_str.split(",")]
    except ValueError:
        print(f"Error: combination_sizes ('{combination_sizes_str}') must be integer(s).")
        sys.exit(1)

    # The remaining arguments are possible flags
    raw_flags = sys.argv[4:]
    
    # Remove duplicates using a set, then sort for consistency
    unique_flags_dict = {}
    for flag in raw_flags:
        # If we've seen this flag before, remove it so when we re-add below
        # it appears at the end in insertion order (Python 3.7+).
        if flag in unique_flags_dict:
            del unique_flags_dict[flag]
        unique_flags_dict[flag] = True

    # Now the dictionary keys are in the order of their *final* appearance.
    unique_flags = list(unique_flags_dict.keys())
    

    # Constant flags always included in every compilation
    constant_flags_list = [
        "-fpermissive",
        "-w",
        "-Wno-implicit-function-declaration",
        "-Wno-implicit-int",
        "-Wno-return-type",
        "-Wno-builtin-redeclared",
        "-Wno-int-conversion",
        "-march=x86-64",
        "-I/usr/include",
        f"-I{INCLUDES_DIR}",
    ]

    print("[*]Always-used constant flags")
    for f in constant_flags_list:
        print(" ", f)
    print()

    print("[*]Unique flags given (duplicates removed)")
    for f in unique_flags:
        print(" ", f)
    print()

    print(f"[*]Combination sizes specified: {combination_sizes}")
    print()

    temp_executable = "./temp_executable"

    # Derive the base name of the test C file (e.g. "test" from "test.c")
    test_c_basename = os.path.splitext(os.path.basename(test_c_path))[0]

    # We'll keep a global counter of how many combos we've tested in total
    total_combo_count = 0

    def is_crash(return_code: int) -> bool:
        return (return_code < 0) or (return_code >= 128)

    # Iterate over each combination size
    for size in combination_sizes:
        if size <= 0:
            print(f"[!][Warning] Invalid combination size: {size}, skipping.")
            continue

        print(f"[*]Now checking {size}-flag combinations")
        
        # Prepare a log file for segfault occurrences
        log_filename = f"{test_c_basename}_{size}.log"
        # Open in write mode (overwrites each time you run)
        with open(log_filename, "w") as log_file:
            # Use combinations() from itertools
            combos = itertools.combinations(unique_flags, size)

            # We'll go through each combination of this size
            for combo in combos:
                total_combo_count += 1
                combo_flags = list(combo)

                # Build the clang command
                cmd = [
                    clang_path,
                    *constant_flags_list,
                    *combo_flags,
                    test_c_path,
                    "-o", temp_executable
                ]

                print(f"[#{total_combo_count}] Compiling (size={size}) -> {' '.join(cmd)}")
                compile_proc = subprocess.run(cmd, capture_output=True)

                if compile_proc.returncode != 0:
                    print(f"  -> Compilation error (return code={compile_proc.returncode}).")
                    print(f"  -> stderr:\n{compile_proc.stderr.decode('utf-8')}")
                    print()
                    if is_crash(compile_proc.returncode):
                        print(f"  -> COMPILE CRASH (returncode={compile_proc.returncode})")
                        log_file.write(f"COMPILE CRASH (rc={compile_proc.returncode}) with flags: {combo_flags}\n")
                    continue

                # If compilation succeeded, run the binary
                run_proc = subprocess.run([temp_executable])
                if is_crash(run_proc.returncode):
                    print(f"  -> RUNTIME CRASH! (execution returncode={run_proc.returncode})")
                    log_file.write(f"RUNTIME CRASH (rc={run_proc.returncode}) with flags: {combo_flags}\n")
                else:
                    print(f"  -> Execution finished (returncode={run_proc.returncode}).")

                print()

        print(f"[*]Finished checking {size}-flag combinations. Crashes (if any) are listed in '{log_filename}'.\n")

    # Cleanup: remove the temporary executable if it exists
    if os.path.exists(temp_executable):
        os.remove(temp_executable)

    print("All done.")

if __name__ == "__main__":
    main()
