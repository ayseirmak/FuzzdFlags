#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fuzz_report.py <OUTPUT_DIR>")
        sys.exit(1)

    output_dir = sys.argv[1]

    # Subdirectories typically used by AFL++
    crash_dir = os.path.join(output_dir, "crashes")
    hang_dir = os.path.join(output_dir, "hangs")
    queue_dir = os.path.join(output_dir, "queue")
    report_file ="/users/user42/fuzz_report.txt"

    # 1) Count queue, crashes, hangs
    crash_count = count_non_readme_files(crash_dir)
    hang_count = count_non_readme_files(hang_dir)
    queue_count = count_non_readme_files(queue_dir)

    with open(report_file, "w") as rep:
        rep.write("=== Fuzzing Summary ===\n")
        rep.write(f"Total queue entries: {queue_count}\n")

        if crash_count == 0 and hang_count == 0:
            rep.write("No crashes or hangs were detected.\n")
        else:
            rep.write(f"Crashes: {crash_count}\n")
            rep.write(f"Hangs: {hang_count}\n\n")

            # List crash files (if any)
            rep.write("=== Crash Files ===\n")
            if crash_count > 0:
                for fname in sorted_non_readme_files(crash_dir):
                    rep.write(f"{fname}\n")
            else:
                rep.write("No crash files.\n")

            rep.write("\n=== Hang Files ===\n")
            if hang_count > 0:
                for fname in sorted_non_readme_files(hang_dir):
                    rep.write(f"{fname}\n")
            else:
                rep.write("No hang files.\n")

        # 2) Analyze queue for:
        #    - Source File Frequency
        #    - Mutated Flags Frequency
        #    - Seed Analysis
        rep.write("\n=== Queue Analysis (Source/Flags) ===\n")

        # The "fixed" flags that clang-options always includes, which we don't count as mutated.
        # Make sure these match exactly what appears in --checker output for your environment.
        FIXED_FLAGS = {
            "-c",
            "-fpermissive",
            "-w",
            "-Wno-implicit-function-declaration",
            "-Wno-implicit-int",
            "-Wno-return-type",
            "-Wno-builtin-redeclared",
            "-Wno-int-conversion",
            "-target",
            "x86_64-linux-gnu",
            "-march=native",
            "-I/usr/include",
            # Adjust if clang-options prints a different include path
            "-I/users/user42/input-include",
        }

        file_name_count = {}  # e.g. {"/path/to/test_97.c": 3, ...}
        flag_count = {}       # e.g. {"-O1": 10, ...}

        # For seed analysis:
        # seed_analysis[<seedName>] = {
        #     "source_file": <path>,
        #     "mutated_flags": set([...])
        # }
        # We'll also have a seed_flag_count for how many seeds contain each mutated flag
        seed_analysis = {}
        seed_flag_count = {}

        if os.path.isdir(queue_dir):
            for fname in sorted_non_readme_files(queue_dir):
                full_path = os.path.join(queue_dir, fname)

                # Distinguish seeds by checking if the file name has e.g. "orig:seedX.bin"
                # Adjust the pattern if your seeds differ (e.g. "orig:seed10.bin")
                is_seed_file, seed_name = check_if_seed_file(fname)

                # Run clang-options in checker mode
                result = subprocess.run(
                    ["/users/user42/build-test/bin/clang-options", "--checker", "--filebin", full_path],
                    capture_output=True,
                    text=True
                )
                stdout = result.stdout

                # Extract the lines for source file and flags
                source_file, all_flags = parse_clang_options_checker(stdout)
                if not source_file:
                    # If no source found, skip
                    continue

                # Update global source file frequency
                file_name_count[source_file] = file_name_count.get(source_file, 0) + 1

                # Filter flags => mutated flags
                mutated_flags = set()
                for fl in all_flags:
                    if fl not in FIXED_FLAGS:
                        mutated_flags.add(fl)

                # Update global flag_count
                for flg in mutated_flags:
                    flag_count[flg] = flag_count.get(flg, 0) + 1

                # If it's a seed file, store data for seed analysis
                if is_seed_file:
                    # Make a record or get existing
                    seed_analysis[seed_name] = {
                        "source_file": source_file,
                        "mutated_flags": mutated_flags
                    }
                    # For each mutated flag, update seed_flag_count
                    for mfl in mutated_flags:
                        seed_flag_count[mfl] = seed_flag_count.get(mfl, 0) + 1

        # 3) Print the 2 "tables" for the entire queue
        rep.write("\n=== Source File Frequency (Entire Queue) ===\n")
        if not file_name_count:
            rep.write("No queue entries or no valid source files found in the queue.\n")
        else:
            for sf, count_val in sorted(file_name_count.items()):
                rep.write(f"{sf} : {count_val}\n")

        rep.write("\n=== Mutated Flags Frequency (Entire Queue) ===\n")
        if not flag_count:
            rep.write("No mutated flags found in the queue (or queue is empty).\n")
        else:
            for flg, count_val in sorted(flag_count.items()):
                rep.write(f"{flg} : {count_val}\n")

        # 4) Seed Analysis Section
        rep.write("\n=== Seed Analysis ===\n")
        if not seed_analysis:
            rep.write("No seed files found in the queue (none matched 'orig:seedX.bin').\n")
        else:
            # Summarize each seed's source file + flags
            rep.write(f"Found {len(seed_analysis)} seed file(s) in the queue.\n\n")
            for seed_name, data in sorted(seed_analysis.items()):
                rep.write(f"Seed Name: {seed_name}\n")
                rep.write(f"  Source File: {data['source_file']}\n")
                if data["mutated_flags"]:
                    rep.write(f"  Mutated Flags ({len(data['mutated_flags'])}):\n")
                    for flg in sorted(data["mutated_flags"]):
                        rep.write(f"    {flg}\n")
                else:
                    rep.write("  Mutated Flags: None\n")
                rep.write("\n")

            # Also show how many seeds contained each mutated flag
            rep.write("-- Seed Flags Frequency --\n")
            if not seed_flag_count:
                rep.write("No mutated flags found among seeds.\n")
            else:
                for flg, count_val in sorted(seed_flag_count.items()):
                    rep.write(f"{flg} : {count_val}\n")

        rep.write("\nEnhanced fuzz report generated at ")
        rep.write(report_file + "\n")


def check_if_seed_file(queue_filename):
    """
    Checks if 'queue_filename' looks like an original seed file, e.g.:
       d:000000,time:0,execs:0,orig:seed1.bin
    Returns (True, "seed1.bin") or (False, None).
    Adjust to your naming scheme as needed.
    """
    # One approach: if "orig:seed" is in the filename, extract the substring
    if "orig:seed" in queue_filename:
        # e.g. queue_filename might be "d:000000,time:0,execs:0,orig:seed1.bin"
        # Let's parse the part after "orig:"
        parts = queue_filename.split("orig:")
        if len(parts) == 2:
            # the second part might be "seed1.bin"
            seed_name = parts[1]
            return True, seed_name
    return False, None

def parse_clang_options_checker(checker_stdout):
    """
    Given the stdout from 'clang-options --checker', extract:
      [Checker] Source File: ...
      [Checker] Flags: ...
    Return: (source_file, [flag1, flag2, ...])
    If not found, returns (None, []).
    """
    source_file = None
    flags_line = None

    for line in checker_stdout.splitlines():
        line = line.strip()
        if line.startswith("[Checker] Source File:"):
            source_file = line.split(":", 1)[1].strip()
        elif line.startswith("[Checker] Flags:"):
            flags_line = line.split(":", 1)[1].strip()

    if not source_file:
        return (None, [])

    if flags_line:
        all_flags = flags_line.split()
    else:
        all_flags = []

    return (source_file, all_flags)

def count_non_readme_files(directory: str) -> int:
    """Returns the number of files in `directory` (excluding 'README') or 0 if missing."""
    if not os.path.isdir(directory):
        return 0
    return sum(1 for f in os.listdir(directory) if f != "README")

def sorted_non_readme_files(directory: str):
    """Return a sorted list of files in `directory` excluding 'README'."""
    if not os.path.isdir(directory):
        return []
    return sorted(f for f in os.listdir(directory) if f != "README")

if __name__ == "__main__":
    main()
# python3 fuzz_report.py ~/output-afl-exp23/default
