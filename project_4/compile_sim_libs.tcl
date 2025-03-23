# TCL script to compile simulation libraries for Vivado
# Run in Vivado Tcl Console with: source compile_sim_libs.tcl

# Set the simulator - use the one you have (xsim, modelsim, questa, ies, vcs, riviera)
set simulator xsim

# Set the output directory for compiled libraries
set compiled_lib_dir [pwd]/compiled_lib

# Create the directory if it doesn't exist
file mkdir $compiled_lib_dir

# Compile the simulation libraries
compile_simlib -simulator $simulator -directory $compiled_lib_dir -verbose

# Update project to use these libraries
set_property compxlib.compiled_library_dir $compiled_lib_dir [current_project]

puts "Simulation libraries compiled to $compiled_lib_dir"
puts "Use these libraries by setting 'Compiled library location' in the project settings"
puts "Or add this to your project .xpr file:"
puts "  set_property compxlib.compiled_library_dir $compiled_lib_dir \[current_project\]"
