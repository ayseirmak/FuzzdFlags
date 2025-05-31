#!/usr/bin/env bash
#/users/user42/extract_fuzz_stat_dir.sh ~/fuzz_analaysis directory of rep1 rep2 rep3 rep4 rep5 rep6
workdir=$1
fields=(
  corpus_count
  saved_crashes
  saved_hangs
  run_time
  execs_done
  execs_per_sec
  pending_total
  max_depth
  bitmap_cvg
  edges_found
  total_edges
  var_byte_count
)


cd "$workdir" || { echo "Could not cd to $workdir"; exit 1; }
out_csv="fuzzer_stats_summary.csv"
{
  for f in "${fields[@]}"; do
      printf ",%s" "$f"
  done
  printf "\n"
} > "$out_csv"

for j in 1 2 3 4 5; do
  dir="fuzz0$j"
  stats_file="$dir/default/fuzzer_stats"
  if [[ ! -f "$stats_file" ]]; then
      echo "Warning: no stats file at $stats_file" >&2
      continue
  fi

  {
      printf "%s" "$dir"
      for f in "${fields[@]}"; do
          val=$(grep "^${f}[[:space:]]*:" "$stats_file" | awk -F: '{ gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }' )
          printf ",%s" "${val:-}"
      done
      printf "\n" 
  } >> "$out_csv"
done
echo "Written summary to $out_csv"
