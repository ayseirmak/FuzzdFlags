#!/usr/bin/env bash
#
# This script:
#  Find the coverage of single repetition

set -e          # Exit on any command failing
set -u          # Treat unset variables as an error
set -o pipefail # Catch errors in piped commands

# If you also want to see each command as it’s executed in the log, do:
set -x

# Decide where you want the log to go. You could also hardcode it, e.g.:
workdir=$1
cov_file=$2
table_name=$3
LOGFILE="$workdir/coverage_analysis.log"

# Redirect *all* script output (stdout + stderr) into $LOGFILE.
# Using exec changes redirections for the entire script from this point forward.
exec >"$LOGFILE" 2>&1

echo "===== STARTING SCRIPT at $(date) ====="
# Move into m2 directory (if it exists)
cd "$workdir" || { echo "Could not cd to $workdir "; exit 1; }

echo
echo "===== PROCESSING single rep $(date) ====="
mkdir -p "$workdir" || { echo "Could not create $workdir"; exit 1; }
cd "$workdir" || { echo "Could not cd to $workdir"; exit 1; }

# 1) Run the coverage table script
#    Adjust paths/names as needed:
/users/user42/5-cov-table.sh "$cov_file" "$table_name"

# 2) Summation commands:
echo "---- Backend Analysis ----"
cat "$table_name" \
  | grep -e'clang/lib/CodeGen/' -e'llvm/lib/CodeGen/' -e'llvm/lib/AsmParser/' -e'llvm/lib/Bitcode/' -e'llvm/lib/MC/'  -e'llvm/lib/MCA/' -e'llvm/lib/LTO/' -e'llvm/lib/ExecutionEngine/' -e'llvm/lib/Linker/' -e'llvm/lib/DebugInfo/' -e'llvm/lib/Support/' -e'llvm/lib/Target/' -e'llvm/utils/TableGen/' \
  | awk -F, '
      # 1. NR==1 -> skip header 
      # 2. Foe each row 2nd col = total_lines; 3rd col  = covered_lines;
      NR > 1 {
        total += $2;
        covered += $3;
        pct       = ($3>0 ? ($3/$2*100) : 0);
        sum_pct  += pct;
        count++;
      }
      END {
        printf "Total Lines: %d\n", total;
        printf "Covered Lines: %d\n", covered;
        printf "Total Coverage: %.2f%%\n", (covered/total)*100;
        printf "Average Coverage: %.2f%%\n", sum_pct/count;
      }'

echo "---- Middle-end Analysis ----"
cat "$table_name" \
  | grep -e'clang/lib/Analysis/' -e'llvm/lib/Analysis/' -e'llvm/lib/BinaryFormat/' -e'llvm/lib/DebugInfo/' -e'llvm/lib/IR/' -e'llvm/lib/IRReader/' -e'llvm/lib/Object/' -e'llvm/lib/ObjectYAML/' -e'llvm/lib/Passes/' -e'llvm/lib/Support/' -e'llvm/lib/Transforms/' \
  | awk -F, '
      # 1. NR==1 -> skip header 
      # 2. Foe each row 2nd col = total_lines; 3rd col  = covered_lines;
      NR > 1 {
        total += $2;
        covered += $3;
        pct       = ($3>0 ? ($3/$2*100) : 0);
        sum_pct  += pct;
        count++;
      }
      END {
        printf "Total Lines: %d\n", total;
        printf "Covered Lines: %d\n", covered;
        printf "Total Coverage: %.2f%%\n", (covered/total)*100;
        printf "Average Coverage: %.2f%%\n", sum_pct/count;
      }'

echo "---- Frontend Analysis ----"
cat "$table_name" \
  | grep -e'clang/include/' -e'clang/lib/APINotes/' -e'clang/lib/AST/' -e'clang/lib/Basic/' -e'clang/lib/Driver/' -e'clang/lib/Edit/' -e'clang/lib/Format/' -e'clang/lib/Frontend/' -e'clang/lib/Frontend/Rewrite/' -e'clang/lib/FrontendTool/' -e'clang/lib/Index/' -e'clang/lib/Lex/' -e'clang/lib/Parse/' -e'clang/lib/Rewrite/' -e'clang/lib/Sema/' -e'clang/lib/Serialization/' -e'clang/lib/StaticAnalyzer/' -e'clang/lib/Tooling/' -e'clang/tools/' -e'llvm/include/' -e'llvm/lib/DebugInfo/' -e'llvm/lib/Demangle/' -e'llvm/lib/InterfaceStub/' -e'llvm/lib/LineEditor/' -e'llvm/lib/Option/' -e'llvm/lib/ProfileData/' -e'llvm/lib/Remarks/' -e'llvm/lib/Support/' -e'llvm/tools/' -e'llvm/unittests/' -e'llvm/utils/count/' -e'llvm/utils/FileCheck/' -e'llvm/utils/not/' -e'llvm/utils/PerfectShuffle/' -e'llvm/utils/yaml-bench/' -e'llvm-build/' -e'/usr/include/' \
  | awk -F, '
      # 1. NR==1 -> skip header 
      # 2. Foe each row 2nd col = total_lines; 3rd col  = covered_lines;
      NR > 1 {
        total += $2;
        covered += $3;
        pct       = ($3>0 ? ($3/$2*100) : 0);
        sum_pct  += pct;
        count++;
      }
      END {
        printf "Total Lines: %d\n", total;
        printf "Covered Lines: %d\n", covered;
        printf "Total Coverage: %.2f%%\n", (covered/total)*100;
        printf "Average Coverage: %.2f%%\n", sum_pct/count;
      }'
      
/users/user42/61-backend-cov-analysis.sh "$workdir"
/users/user42/62-middleend-cov-analysis.sh "$workdir"
cd ..

echo "===== FINISHED SCRIPT at $(date) ====="

# End of script
