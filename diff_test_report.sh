#!/usr/bin/env bash
# Usage: ./run_diff_test.sh <fuzzed_queue_dir> <diff_out_dir>

if [ $# -lt 2 ]; then
  echo "Usage: $0 <fuzzed_queue_dir> <diff_out_dir>"
  exit 1
fi

FUZZED_DIR="$1"
OUT_DIR="$2"
mkdir -p "$OUT_DIR"

DIFF_REPORT="$OUT_DIR/diff_report.txt"
> "$DIFF_REPORT"


###############################################################################
# Additional Folders for Crashes, Hangs, Mismatches
###############################################################################
CRASH_DIR="$OUT_DIR/Crashes"
HANG_DIR="$OUT_DIR/Hangs"
MISMATCH_DIR="$OUT_DIR/MismatchLogs"

mkdir -p "$CRASH_DIR" "$HANG_DIR" "$MISMATCH_DIR"

CRASH_REPORT="$CRASH_DIR/crash_report.txt"
HANG_REPORT="$HANG_DIR/hang_report.txt"
MISMATCH_REPORT="$MISMATCH_DIR/mismatch_report.txt"

> "$CRASH_REPORT"
> "$HANG_REPORT"
> "$MISMATCH_REPORT"

################################################################################
# CONFIG
################################################################################

CLANG_OPTIONS_BIN="/users/user42/build-test/bin/clang-options"

# The three compilers to test. We'll parse the parent directory name
# for "gcc-14", "gcc-11", or "llvm-19".
COMPILERS=(
  "/opt/gcc-14/bin/gcc"
  "/opt/gcc-11/bin/gcc"
  "/opt/llvm-19/bin/clang"
)

COMPILE_TIMEOUT=5
RUN_TIMEOUT=50

# Base flags for GCC
BASE_FLAGS_GCC=(
  "-O0"
  "-fpermissive"
  "-w"
  "-Wno-implicit-function-declaration"
  "-Wno-implicit-int"
  "-Wno-return-type"
  "-Wno-builtin-declaration-mismatch"
  "-Wno-int-conversion"
  "-march=native"
  "-lm"
  "-I/usr/include"
  "-I/users/user42/input-include"
)

# Base flags for Clang
BASE_FLAGS_CLANG=(
  "-fpermissive"
  "-w"
  "-Wno-implicit-function-declaration"
  "-Wno-implicit-int"
  "-Wno-return-type"
  "-Wno-builtin-redeclared"
  "-Wno-int-conversion"
  "-target" "x86_64-linux-gnu"
  "-march=native"
  "-I/usr/include"
  "-I/users/user42/input-include"
)

# Clang fixed flags to remove from mutated set
CLANG_FIXED_FLAGS=(
  "-c"
  "-fpermissive"
  "-w"
  "-Wno-implicit-function-declaration"
  "-Wno-implicit-int"
  "-Wno-return-type"
  "-Wno-builtin-redeclared"
  "-Wno-int-conversion"
  "-target"
  "x86_64-linux-gnu"
  "-march=native"
  "-I/usr/include"
  "-I/users/user42/input-include"
)

# This dictionary will store short reasons for compilation fails or execution fails
declare -A COMPILATION_EXPLANATIONS
declare -A EXECUTION_EXPLANATIONS


################################################################################
# PRINT HEADER
################################################################################
{
  echo "# ================================================================================================="
  echo "#              Differential Testing Report - (Gcc-11.4.0 Gcc-14.2.0 & Clang-19.1.7)"
  echo "# ================================================================================================="
  echo ""
  echo "Fuzzed input dir: $FUZZED_DIR"
  echo "Output dir: $OUT_DIR"
  echo ""
} >> "$DIFF_REPORT"

################################################################################
# HELPER FUNCTIONS
################################################################################

interpret_result() {
  local rc="$1"
  local log_file="$2"

  if [ "$rc" -eq 124 ]; then
    echo "Timeout"
    return
  fi
  if [ "$rc" -gt 128 ]; then
    sig=$((rc - 128))
    echo "Crashed-with-signal:$sig"
    return
  fi
  if grep -iq "undefined behavior" "$log_file"; then
    echo "UndefinedBehavior"
    return
  fi

  if [ "$rc" -eq 0 ]; then
    echo "OK"
  else
    echo "Fail($rc)"
  fi
}

is_in_array() {
  local needle="$1"
  shift
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

remove_clang_fixed_flags() {
  local all_flags_str="$1"
  IFS=' ' read -r -a arr <<< "$all_flags_str"

  declare -a mutated
  for f in "${arr[@]}"; do
    if ! is_in_array "$f" "${CLANG_FIXED_FLAGS[@]}"; then
      mutated+=("$f")
    fi
  done
  echo "${mutated[*]}"
}

decide_base_flags() {
  local cname="$1"
  if [[ "$cname" == "gcc-14" || "$cname" == "gcc-11" ]]; then
    echo "${BASE_FLAGS_GCC[*]}"
  else
    echo "${BASE_FLAGS_CLANG[*]}"
  fi
}

################################################################################
# do_compile_and_run
# do_compile_and_run <compiler> <source> <mutated_flags> <outbase>
################################################################################
do_compile_and_run() {
  local compiler="$1"
  local src="$2"
  local mutated_flags_str="$3"
  local outbase="$4"

  # compiler_name e.g. "gcc-14"
  local comp_dir
  comp_dir=$(dirname "$(dirname "$compiler")")
  local compiler_name
  compiler_name=$(basename "$comp_dir")

  # pick base flags
  local base_str
  base_str="$(decide_base_flags "$compiler_name")"

  # convert to arrays
  IFS=' ' read -r -a base_arr <<< "$base_str"
  IFS=' ' read -r -a mut_arr  <<< "$mutated_flags_str"
  declare -a combined

  # If it's GCC => only base. If Clang => base + mutated
  if [[ "$compiler_name" == "gcc-14" || "$compiler_name" == "gcc-11" ]]; then
    combined=("${base_arr[@]}")
  else
    combined=("${base_arr[@]}" "${mut_arr[@]}")
  fi

  # remove '-c'
  declare -a final_arr=()
  for fl in "${combined[@]}"; do
    if [[ "$fl" != "-c" ]]; then
      final_arr+=("$fl")
    fi
  done
  local final_flags="${final_arr[*]}"

  local bin_out="$OUT_DIR/$outbase-$compiler_name.out"
  local compile_log="$OUT_DIR/$outbase-$compiler_name.compile.log"
  local run_log="$OUT_DIR/$outbase-$compiler_name.run.log"

  
  # =======================
  # Compilation
  # =======================
  {
    echo "[*] Compiling with $compiler_name"
    echo "Command: timeout ${COMPILE_TIMEOUT}s $compiler $final_flags $src -o $bin_out"
  } > "$compile_log"

  (timeout "${COMPILE_TIMEOUT}s" "$compiler" $final_flags "$src" -o "$bin_out")>> "$compile_log" 2>&1
  comp_rc=$?  # e.g. 1 or 124
  echo "***$comp_rc"
  local comp_res
  comp_res=$(interpret_result "$comp_rc" "$compile_log")
  echo "$comp_res"
 
  if grep -Eq "error:" "$compile_log"; then
    comp_res="Fail(0)"
  fi
 # store the compilation outcome in an associative array (for the final summary)
  # e.g. COMPILATION_EXPLANATIONS["gcc-14"]="OK" or "Fail(1)" or "Timeout" or "Crashed-with-signal:6"
  COMPILATION_EXPLANATIONS["$compiler_name"]="$comp_res"
  echo "[*] $comp_res"
  echo "$outbase"

  if [[ "$comp_res" == Fail* ]]; then
    # store short snippet
      local snippet
      snippet=$(sed -n '3,6p' "$compile_log")
      COMPILATION_EXPLANATIONS["$compiler_name"]+=" => (Reason)\n$snippet"
    # no executable => no run
    return  # done
  fi

  # if compilation was OK => do run
  {
    echo "[*] Running $bin_out with ${RUN_TIMEOUT}s timeout"
  } > "$run_log"

  (timeout "${RUN_TIMEOUT}s" "$bin_out") >> "$run_log" 2>&1
  run_rc=$?
  
  local run_res
  run_res=$(interpret_result "$run_rc" "$run_log")
  if grep -Eq "error:" "$run_log"; then
    run_res="Fail(0)"
  fi
  # store the run outcome in an array
  EXECUTION_EXPLANATIONS["$compiler_name"]="$run_res"

  if [[ "$run_res" == Fail* ]]; then
      local snippet
      snippet=$(sed -n '3,6p' "$run_log")
      EXECUTION_EXPLANATIONS["$compiler_name"]+=" => (Reason)\n$snippet"
  fi
}

################################################################################
# MAIN
################################################################################
for f in "$FUZZED_DIR"/*; do
  if [ -d "$f" ] || [ "$(basename "$f")" == "README" ]; then
    continue
  fi

  # decode with clang-options
  checker_out=$($CLANG_OPTIONS_BIN --checker --filebin "$f" 2>/dev/null || true)
  local_source=$(echo "$checker_out" | grep -F "[Checker] Source File:" | cut -d':' -f2- | xargs)
  local_flags=$(echo "$checker_out" | grep -F "[Checker] Flags:" | cut -d':' -f2- | xargs)

  if [ -z "$local_source" ] || [ ! -f "$local_source" ]; then
    echo "=== Skipping $f: no valid Source File found! ===" >> "$DIFF_REPORT"
    continue
  fi

  # remove clang fixed => mutated only
  mutated_flags="$(remove_clang_fixed_flags "$local_flags")"

  out_base="case_$(basename "$f")"

  echo "" >> "$DIFF_REPORT"
  echo "===================================================================================================">> "$DIFF_REPORT"
  echo "Fuzzed Input: $f" >> "$DIFF_REPORT"
  echo "Decoded Source: $local_source" >> "$DIFF_REPORT"
  echo "Decoded Flags (full): $local_flags" >> "$DIFF_REPORT"
  echo "Mutated Flags (no clang fixed): $mutated_flags" >> "$DIFF_REPORT"

  # clear out old dictionary entries for this fuzz input
  for cc in "gcc-14" "gcc-11" "llvm-19"; do
    COMPILATION_EXPLANATIONS["$cc"]=""
    EXECUTION_EXPLANATIONS["$cc"]=""
  done

  # For each compiler => compile & run
  for cpath in "${COMPILERS[@]}"; do
    do_compile_and_run "$cpath" "$local_source" "$mutated_flags" "$out_base"
  done

  # Print the final summary

  # 1) Compilation results
  echo >> "$DIFF_REPORT"
  echo "Compilation ---------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${COMPILATION_EXPLANATIONS["$order"]}"
    echo "   $order => $outcome"
    if [ -n "$outcome" ]; then
      echo "   $order => "${outcome%% *}"" >> "$DIFF_REPORT"
    else
      echo "   $order => (No compilation done?)" >> "$DIFF_REPORT"
    fi
  done
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${COMPILATION_EXPLANATIONS["$order"]}"
    # if it starts with "Fail" or "Timeout", we print the snippet
    if [[ "$outcome" == Fail* || "$outcome" == Timeout* || "$outcome" == Crashed* ]]; then
      echo "---------------------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
      echo "why $order could not compile?" >> "$DIFF_REPORT"
      echo -e "$outcome" >> "$DIFF_REPORT"
    fi
  done

  # 2) Execution results
  echo >> "$DIFF_REPORT"
  echo "Execution -----------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${EXECUTION_EXPLANATIONS["$order"]}"
    if [ -z "$outcome" ]; then
      # means we never got to run it, presumably compilation failed
      outcome="(No-Execution)"
    fi
    echo "   $order => "${outcome%% *}"" >> "$DIFF_REPORT"
  done
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${EXECUTION_EXPLANATIONS["$order"]}"
    if [[ "$outcome" == Fail* || "$outcome" == Timeout* || "$outcome" == Crashed* ]]; then
      echo "---------------------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
      echo "why $order could not execute?" >> "$DIFF_REPORT"
      echo -e "$outcome" >> "$DIFF_REPORT"
      echo >> "$DIFF_REPORT"

    elif [ "$outcome" == "(No-Execution)" ]; then
      echo "---------------------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
      echo "why $order had no execution? => possibly compilation failed" >> "$DIFF_REPORT"
      echo >> "$DIFF_REPORT"
    fi
  done
  
  #############################################################################
  # Copy logs for Crash / Timeout compilers to specialized folders
  #############################################################################
  # We'll also produce a mini-report in those folders:
  # ----------------------------------------------------------
# 1) Check if any compiler crashed or timed out
# ----------------------------------------------------------
crash_found=0
hang_found=0

for cc in "gcc-14" "gcc-11" "llvm-19"; do
  comp_outcome="${COMPILATION_EXPLANATIONS[$cc]}"
  exec_outcome="${EXECUTION_EXPLANATIONS[$cc]}"
  # If either comp_outcome or exec_outcome contains "Crashed-with-signal"
  if [[ "$comp_outcome" = Crashed-with-signal* || "$exec_outcome" = Crashed-with-signal* ]]; then
    crash_found=1
  fi
  # If either is "Timeout", mark hang
  if [[ "$comp_outcome" == Timeout* || "$exec_outcome" == Timeout* ]]; then
    hang_found=1
  fi
done

if [ $crash_found -eq 1 ]; then
  # We'll copy logs for *all compilers* to a single folder for this case
  crash_folder="$CRASH_DIR/$out_base"
  mkdir -p "$crash_folder"

  # Create or append the mini-report
  mini_report="$crash_folder/mini-report.txt"
  {
    echo "=== Crash mini-report for case $out_base ==="
    echo "All compiler outcomes for this case:"
    echo "All compiler outcomes for this case (compilation + execution), plus logs"
  } >> "$mini_report"

  for cc in "gcc-14" "gcc-11" "llvm-19"; do
    comp_outcome="${COMPILATION_EXPLANATIONS[$cc]}"
    exec_outcome="${EXECUTION_EXPLANATIONS[$cc]}"
    compile_log="$OUT_DIR/$out_base-$cc.compile.log"
    run_log="$OUT_DIR/$out_base-$cc.run.log"

    # Copy logs
    cp -v "$compile_log" "$crash_folder" 2>/dev/null || true
    cp -v "$run_log" "$crash_folder" 2>/dev/null || true

    # Summarize outcomes
    echo "Compiler: $cc" >> "$mini_report"
    echo "  Compilation => $comp_outcome" >> "$mini_report"
    echo "  Execution   => $exec_outcome" >> "$mini_report"
    echo "" >> "$mini_report"

    echo "---- $cc compile log (first 10 lines) ----" >> "$mini_report"
    sed -n '1,10p' "$compile_log" >> "$mini_report" 2>/dev/null
    echo "" >> "$mini_report"
    echo "---- $cc run log (first 10 lines) ----" >> "$mini_report"
    sed -n '1,10p' "$run_log" >> "$mini_report" 2>/dev/null
    echo "" >> "$mini_report"
  done

  echo "Detailed logs: $crash_folder" >> "$CRASH_REPORT"
  echo "Case: $out_base" >> "$CRASH_REPORT"
  echo "" >> "$CRASH_REPORT"
fi

if [ $hang_found -eq 1 ]; then
  hang_folder="$HANG_DIR/$out_base"
  mkdir -p "$hang_folder"
  mini_report="$hang_folder/mini-report.txt"
  {
    echo "=== Hang mini-report for case $out_base ==="
    echo "All compiler outcomes for this case:"
  } >> "$mini_report"

  for cc in "gcc-14" "gcc-11" "llvm-19"; do
    comp_outcome="${COMPILATION_EXPLANATIONS[$cc]}"
    exec_outcome="${EXECUTION_EXPLANATIONS[$cc]}"
    compile_log="$OUT_DIR/$out_base-$cc.compile.log"
    run_log="$OUT_DIR/$out_base-$cc.run.log"

    cp -v "$compile_log" "$hang_folder" 2>/dev/null || true
    cp -v "$run_log" "$hang_folder" 2>/dev/null || true

    echo "Compiler: $cc" >> "$mini_report"
    echo "  Compilation => $comp_outcome" >> "$mini_report"
    echo "  Execution   => $exec_outcome" >> "$mini_report"
    echo "" >> "$mini_report"

    echo "---- $cc compile log (first 10 lines) ----" >> "$mini_report"
    sed -n '1,10p' "$compile_log" >> "$mini_report" 2>/dev/null
    echo "" >> "$mini_report"
    echo "---- $cc run log (first 10 lines) ----" >> "$mini_report"
    sed -n '1,10p' "$run_log" >> "$mini_report" 2>/dev/null
    echo "" >> "$mini_report"
  done

  echo "Detailed logs: $hang_folder" >> "$HANG_REPORT"
  echo "Case: $out_base" >> "$HANG_REPORT"
  echo "" >> "$HANG_REPORT"
fi

  ###############################################################################
  # Remove the "[*] Running ..." lines from all run logs for clarity
  ###############################################################################
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    run_log="$OUT_DIR/$out_base-$order.run.log"
    # If the run log exists, remove lines that start with "[*] Running "
    if [ -f "$run_log" ]; then
      sed -i '/^\[\*\] Running /d' "$run_log"
    fi
  done

  #############################################################################
  # Pairwise compare *all compilers that have run logs*, not just OK
  #############################################################################
  declare -a run_compilers=()
for order in "gcc-14" "gcc-11" "llvm-19"; do
  outcome="${EXECUTION_EXPLANATIONS["$order"]}"
  if [ -n "$outcome" ] && [ "$outcome" != "(No-Execution)" ]; then
    run_compilers+=("$order")
  fi
done

mismatch_detected=0
if [ "${#run_compilers[@]}" -gt 1 ]; then
  for ((i=0; i<${#run_compilers[@]}-1; i++)); do
    for ((j=i+1; j<${#run_compilers[@]}; j++)); do
      cA="${run_compilers[$i]}"
      cB="${run_compilers[$j]}"
      outcomeA="${EXECUTION_EXPLANATIONS[$cA]}"
      outcomeB="${EXECUTION_EXPLANATIONS[$cB]}"

      # 1) If one crashed and the other did not, mismatch
      if [[ "$outcomeA" = Crashed-with-signal* || "$outcomeB" = Crashed-with-signal* ]] &&
         [[ "$outcomeA" != "$outcomeB" ]]; then
        mismatch_detected=1
        echo "[Mismatch] $cA vs $cB (crash vs non-crash)" >> "$DIFF_REPORT"
      else
        # 2) Otherwise, check logs if they both have .run.log
        logA="$OUT_DIR/$out_base-$cA.run.log"
        logB="$OUT_DIR/$out_base-$cB.run.log"
        if [[ -f "$logA" && -f "$logB" ]]; then
          if ! diff -q "$logA" "$logB" >/dev/null 2>&1; then
            mismatch_detected=1
            echo "[Mismatch] $cA vs $cB" >> "$DIFF_REPORT"
          fi
        fi
      fi
    done
  done
fi

if [ "$mismatch_detected" -eq 1 ]; then
    echo "[Mismatch found for case $out_base]" >> "$DIFF_REPORT"
    mismatch_folder="$MISMATCH_DIR/$out_base"
    mkdir -p "$mismatch_folder"

    # Copy compile + run logs for ALL compilers
    mini_report="$mismatch_folder/mini-report.txt"
    {
      echo "=== Mismatch mini-report for case $out_base ==="
      echo "All compilers in run_compilers: ${run_compilers[*]}"
      echo "Storing compile + run logs for each to $mismatch_folder"
      echo ""
    } >> "$mini_report"

    for cc in "gcc-14" "gcc-11" "llvm-19"; do
     comp_outcome="${COMPILATION_EXPLANATIONS[$cc]}"
     exec_outcome="${EXECUTION_EXPLANATIONS[$cc]}"
     compile_log="$OUT_DIR/$out_base-$cc.compile.log"
     run_log="$OUT_DIR/$out_base-$cc.run.log"

      cp -v "$compile_log" "$mismatch_folder" 2>/dev/null || true
      cp -v "$run_log" "$mismatch_folder" 2>/dev/null || true

      echo "Compiler: $cc" >> "$mini_report"
      echo "  Compilation => $comp_outcome" >> "$mini_report"
      echo "  Execution   => $exec_outcome" >> "$mini_report"
      echo "" >> "$mini_report"

      echo "---- $cc compile log (first 10 lines) ----" >> "$mini_report"
      sed -n '1,10p' "$compile_log" >> "$mini_report" 2>/dev/null
      echo "" >> "$mini_report"

      echo "---- $cc run log (first 10 lines) ----" >> "$mini_report"
      sed -n '1,10p' "$run_log" >> "$mini_report" 2>/dev/null
      echo "" >> "$mini_report"
    done

    {
      echo "== Mismatch for $out_base =="
      echo "Logs copied to $mismatch_folder"
    } >> "$MISMATCH_REPORT"
else
  echo "**All matched among those successfully compiled**" >> "$DIFF_REPORT"
fi
  
done

echo "" >> "$DIFF_REPORT"
echo "=== End of Differential Testing ===" >> "$DIFF_REPORT"
echo "Report saved to $DIFF_REPORT"
#./test10.sh small-queue/ 10-diff-test-out
