# === Parameter sweep ranges ===
set ghw_list {2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32}
set rounds_list {2 3 4 5 6 7 8 9 10}

# === Begin sweep ===
foreach ghr $ghw_list {
  foreach rounds $rounds_list {
    puts "\n=== Running GHR_WIDTH=$ghr, ROUNDS=$rounds ==="

    # Set parameters
    set_parameter design_mode "rtl"
    set_parameter language_mode "sv"
    set_parameter define "GHR_WIDTH=$ghr,ROUNDS=$rounds"

    # Read files (replacing any existing ones)
    read_file -format sverilog -replace complex_ghr_hasher.v
    read_file -format sverilog -replace complex_hashed_global_branch_predictor.v
    read_file -format sverilog -replace tb_global_predictor_checker.sv

    # Re-elaborate
    elaborate -force

    # Run BMC
    set_engine bmc
    prove -all

    # Save results
    set output_dir "results/GHR${ghr}_R${rounds}"
    file mkdir $output_dir

    report_property -all > "$output_dir/properties.txt"
    report_stats -property -all > "$output_dir/stats.txt"
  }
}

exit
