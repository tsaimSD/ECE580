foreach ghr $ghw_list {
  foreach rounds $rounds_list {
    puts "\n=== Running GHR_WIDTH=$ghr, ROUNDS=$rounds ==="

    remove_design -all
    remove_file -all

    set_option design_mode rtl
    set_option language_mode sv
    set_option define "GHR_WIDTH=$ghr,ROUNDS=$rounds"

    read_file -format sverilog complex_ghr_hasher.v
    read_file -format sverilog complex_hashed_global_branch_predictor.v
    read_file -format sverilog tb_global_predictor_checker.sv

    elaborate
    set_engine bmc
    prove -all

    set output_dir "results/GHR${ghr}_R${rounds}"
    file mkdir $output_dir

    report_property -all > "$output_dir/properties.txt"
    report_stats -property -all > "$output_dir/stats.txt"
  }
}
exit

exit
