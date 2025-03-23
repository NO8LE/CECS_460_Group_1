# TCL script to compile simulation libraries for Vivado
# Run in Vivado Tcl Console with: source compile_libs.tcl

puts "Starting simulation library compilation..."

# Set the simulator - use the one you have (xsim, modelsim, questa, ies, vcs, riviera)
set simulator xsim

# Set the output directory for compiled libraries - use absolute path
set compiled_lib_dir [file normalize "[pwd]/compiled_libs"]

# Print current directory for verification
puts "Current directory: [pwd]"
puts "Will create compiled libraries at: $compiled_lib_dir"

# Create the directory if it doesn't exist
file mkdir $compiled_lib_dir

# Compile the simulation libraries
puts "Compiling libraries with command: compile_simlib -simulator $simulator -directory $compiled_lib_dir"
compile_simlib -simulator $simulator -directory $compiled_lib_dir

# Attempt to update project to use these libraries
if {[catch {current_project} result]} {
    puts "No current project found. You'll need to manually set the compiled library path."
} else {
    set_property compxlib.compiled_library_dir $compiled_lib_dir [current_project]
    puts "Project updated to use compiled libraries"
}

puts "Simulation libraries compilation complete"
puts "Libraries location: $compiled_lib_dir"
puts "You can also add this manually to your project settings:"
puts "  set_property compxlib.compiled_library_dir $compiled_lib_dir \[current_project\]"
