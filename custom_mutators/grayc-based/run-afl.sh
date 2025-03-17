# Set AFL_CUSTOM_MUTATOR_ONLY=1 if wants to remove our contribution
# /home/ubuntu/gem5-ssbse-challenge-2023/build/X86/gem5.opt = should be clangoptions
AFL_NO_AFFINITY=1 AFL_SHUFFLE_QUEUE=1 AFL_CUSTOM_MUTATOR_ONLY=0 AFL_DUMB_FORKSRV=1 AFL_FAST_CAL=1 AFL_IGNORE_PROBLEMS=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
AFL_SKIP_BIN_CHECK=1 AFL_MAP_SIZE=1200000 AFL_CUSTOM_MUTATOR_LIBRARY="$cm_path/cm-jm.so;$cm_path/cm-dupm.so;$cm_path/cm-cm.so;$cm_path/cm-delm.so;$cm_path/cm-am.so;$cm_path/cm-em.so" \
$afl -m 50000 -t 99000 -i $input -o $output -- /home/ubuntu/gem5-ssbse-challenge-2023/build/X86/gem5.opt \
/home/ubuntu/ASEGem5/hello-custom-binary-Ex.py --isa X86 --input @@
