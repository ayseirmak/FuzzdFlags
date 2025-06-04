# AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_DEBUG_CHILD_OUTPUT=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_SHUFFLE_QUEUE=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \ 
# afl-fuzz -i /users/user42/input-seeds -m none -t 500 -T 10 -o /users/user42/output-afl -- /users/a_irmak/build/bin/clang-options --filebin @@

#  USE FULL PATHS
input=$1     # E.G. /users/user42/input-seeds
output=$2    # E.G. /users/user42/output-afl
resume=$3    # 0 - new run, 1 - resume
targetbin=$4  # E.G. /users/user42/build-test/bin/clang-options

date
if [ $# -le 3 ]; then
    echo "Usage: $0 <input> <output> <resume_flag> <target>"
    exit 1
fi


if [ "$resume" -eq 1 ]; then
    # Resume fuzzing
    AFL_MAP_SIZE=4194304 AFL_USE_ASAN=0 AFL_DEBUG_CHILD_OUTPUT=1 AFL_SHUFFLE_QUEUE=1 AFL_NO_AFFINITY=1 \
AFL_SKIP_CPUFREQ=1 AFL_AUTORESUME=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
afl-fuzz -m none -t 500 -T 10 -i $input -o $output -- $targetbin --filebin @@
else
    # Starts a new fuzzing
    AFL_MAP_SIZE=4194304 AFL_USE_ASAN=0 AFL_DEBUG_CHILD_OUTPUT=1 AFL_SHUFFLE_QUEUE=1 AFL_NO_AFFINITY=1 \
AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
afl-fuzz -m none -t 500 -T 10 -i $input -o $output -- $targetbin --filebin @@ 
fi
echo "==End Fuzzing round, script 4=="
date
echo "input=$1; output=$2; resume=$3; targetbin=$4"
