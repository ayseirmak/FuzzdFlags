 AFL_NO_AFFINITY=1 AFL_SHUFFLE_QUEUE=1 AFL_CUSTOM_MUTATOR_ONLY=1 AFL_DUMB_FORKSRV=1 AFL_FAST_CAL=1 AFL_IGNORE_PROBLEMS=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
AFL_SKIP_BIN_CHECK=1 AFL_MAP_SIZE=1200000 AFL_CUSTOM_MUTATOR_LIBRARY="$cm_path/cm-gem5-save.so;$cm_path/cm-gem5-save-bin.so;$cm_path/cm-gem5-save-types.so" \
$afl -m 50000 -t 99000 -i $input -o $output -- /home/ubuntu/gem5-ssbse-challenge-2023/build/X86/gem5.opt \
/home/ubuntu/ASEGem5/hello-custom-binary-Ex.py --isa X86 --input @@
