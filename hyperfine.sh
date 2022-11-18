#!/bin/bash


readonly python="reservoir_sampling"
readonly nim="reservoir_samplingnim"
readonly rust="./.local/bin/reservoir_sampling"
readonly tmp_src=$(mkdir -p benches && mktemp "./benches/reservoir_sampling.corpus.XXXXX")

readonly corpus=${1:-$PORTAGE/corpora/bac-lac.2021/bitextor_2018/201808/permanent/en-fr.deduped.txt.gz}
readonly sample_sizes=${2:-1000,5000,10000}
readonly max_stream_size=${3:-500000}



function install {
   #cargo build --release
   cargo install --root $PWD/.local --git https://github.com/SamuelLarkin/reservoir_sampling_rs
   python3 -m pip install git+https://github.com/SamuelLarkin/reservoir_sampling.git@latest
   nimble install https://github.com/SamuelLarkin/reservoir_sampling.nim
}



function speedtest {
   echo "Sample size(s): $sample_sizes}"
   echo "Maximum stream size: $max_stream_size"
   echo "Population stream: $corpus"

   hyperfine \
      --shell bash \
      --prepare "zcat --force $corpus | head -n $max_stream_size > $tmp_src" \
      --cleanup "rm $tmp_src" \
      --export-json hyperfine.text.json \
      --style full \
      --parameter-list sample_size $sample_sizes \
      "$nim    --size {sample_size} < $tmp_src" \
      "$python --size {sample_size} unweighted $tmp_src" \
      "$rust   --size {sample_size} unweighted < $tmp_src"
      #"$python --size {sample_size} weighted $tmp_src <(cut -f 8 < $tmp_src)"
      #"$rust   --size {sample_size} weighted $tmp_src <(cut -f 8 < $tmp_src)"
}


speedtest
#speedtest \
#| tee \
#> hyperfine.text.results
