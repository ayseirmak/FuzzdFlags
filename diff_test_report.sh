#!/usr/bin/env bash
set -euo pipefail

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
  # We'll only label "Timeout" or "Fail(...)". We can also do Segfault if you want,
  # but you said you're ignoring segfault / UB for now and only care about success vs fail vs timeout.
  
  # If rc=124 => "Timeout"
  if [ "$rc" -eq 124 ]; then
    echo "Timeout"
    return
  fi
  # If nonzero => "Fail(#)"
  if [ "$rc" -eq 0 ]; then
    echo "OK"
    return
  else
    echo "Fail($rc)"
    return
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
# do_compile_and_run <compiler> <source> <mutated_flags> <outbase>
#   1) decide base flags (GCC or Clang)
#   2) combine -> final_flags
#   3) compile => log => interpret
#   4) if success => run => log => interpret
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

  if ! timeout "${COMPILE_TIMEOUT}s" "$compiler" $final_flags "$src" -o "$bin_out" >> "$compile_log" 2>&1
  then
    comp_rc=$?  # e.g. 1 or 124
    echo "[!] Compile step had a nonzero exit code ($comp_rc), but continuing..."
  else
    comp_rc=0
  fi
  echo "***$comp_rc"
  local comp_res
  comp_res=$(interpret_result "$comp_rc" "$compile_log")
  echo "$comp_res"
 
  if grep -Eq "error:" "$compile_log"; then
    comp_res="Fail(0)"
  fi
 # store the compilation outcome in an associative array (for the final summary)
  # e.g. COMPILATION_EXPLANATIONS["gcc-14"]="OK" or "Fail(1)" or "Timeout"
  COMPILATION_EXPLANATIONS["$compiler_name"]="$comp_res"
  echo "[*] $comp_res"
  echo "$outbase"

  if [[ "$comp_res" != "OK" ]]; then
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

  if ! timeout "${RUN_TIMEOUT}s" "$bin_out" >> "$run_log" 2>&1
  then
     run_rc=$?
  else
    run_rc=0
  fi

  local run_res
  run_res=$(interpret_result "$run_rc" "$run_log")
  if grep -Eq "error:" "$run_log"; then
    run_res="Fail(0)"
  fi
  # store the run outcome in an array
  EXECUTION_EXPLANATIONS["$compiler_name"]="$run_res"

  if [[ "$run_res" != "OK" ]]; then
      local snippet
      snippet=$(sed -n '3,6p' "$compile_log")
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
  echo "denemeee"

  # For each compiler => compile & run
  for cpath in "${COMPILERS[@]}"; do
    do_compile_and_run "$cpath" "$local_source" "$mutated_flags" "$out_base"
  done

  # Print the final summary in your desired format:

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
    if [[ "$outcome" == Fail* || "$outcome" == Timeout* ]]; then
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
    if [[ "$outcome" == Fail* || "$outcome" == Timeout* ]]; then
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
  # If any compilers failed or timed out, print the reason
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${EXECUTION_EXPLANATIONS["$order"]}"
    if [[ "$outcome" == Fail* || "$outcome" == Timeout* ]]; then
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

  ###############################################################################
  # Remove the "[*] Running ..." lines from all run logs for clarity
  # (Insert this step after the runs have completed)
  ###############################################################################
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    run_log="$OUT_DIR/$out_base-$order.run.log"
    # If the run log exists, remove lines that start with "[*] Running "
    if [ -f "$run_log" ]; then
      sed -i '/^\[\*\] Running /d' "$run_log"
    fi
  done

  ###############################################################################
  # Pairwise compare for "OK" compilers (execution stage)
  ###############################################################################
  declare -a ok_compilers=()
  for order in "gcc-14" "gcc-11" "llvm-19"; do
    outcome="${EXECUTION_EXPLANATIONS["$order"]}"
    if [[ "$outcome" == "OK" ]]; then
      ok_compilers+=("$order")
    fi
  done

  echo >> "$DIFF_REPORT"
  echo "#--------------------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
  mismatch_detected=0
  if [ "${#ok_compilers[@]}" -gt 1 ]; then
    # We have at least 2 compilers with "OK" => do pairwise diff
    for ((i=0; i<${#ok_compilers[@]}-1; i++)); do
      for ((j=i+1; j<${#ok_compilers[@]}; j++)); do
        cA="${ok_compilers[$i]}"
        cB="${ok_compilers[$j]}"
        logA="$OUT_DIR/$out_base-$cA.run.log"
        logB="$OUT_DIR/$out_base-$cB.run.log"

        if [[ -f "$logA" && -f "$logB" ]]; then
          if ! diff -q "$logA" "$logB" >/dev/null 2>&1; then
            mismatch_detected=1
            echo "[Mismatch] $cA vs $cB" >> "$DIFF_REPORT"
          fi
        fi
      done
    done
  fi

  if [ "${#ok_compilers[@]}" -ge 2 ] && [ "$mismatch_detected" -eq 0 ]; then
    echo "**All match among OK compilers" >> "$DIFF_REPORT"
  fi
  echo "#--------------------------------------------------------------------------------------------------" >> "$DIFF_REPORT"
  
done

echo "" >> "$DIFF_REPORT"
echo "=== End of Differential Testing ===" >> "$DIFF_REPORT"
echo "Report saved to $DIFF_REPORT"

#./diff_test_report.sh ~/output-afl-exp23/default/queue/ diff-test-out
