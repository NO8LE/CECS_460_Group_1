# Xilinx Simulation Libraries Compiler Script
# Run in Vivado Tcl Console with: source compile_xilinx_libs.tcl
# --------------------------------------------------------
# This script compiles all required simulation libraries for Xilinx designs
# and configures your project to use them, addressing the 
# "[Vivado 12-13277] Compiled library path does not exist" warnings.

puts "========================================================="
puts "Starting Xilinx Simulation Library Compilation..."
puts "========================================================="

# Set the simulator - use the one you have (xsim, modelsim, questa, ies, vcs, riviera)
set simulator xsim

# Set the output directory for compiled libraries - use absolute path for reliability
set compiled_lib_dir [file normalize "[pwd]/xilinx_sim_libs"]

# Print current directory and target directory for verification
puts "Current directory: [pwd]"
puts "Will create compiled libraries at: $compiled_lib_dir"

# Create the directory if it doesn't exist
file mkdir $compiled_lib_dir

# Compile the simulation libraries with verbose output
puts "Compiling libraries (this may take several minutes)..."
puts "Command: compile_simlib -simulator $simulator -directory $compiled_lib_dir -verbose"

if {[catch {compile_simlib -simulator $simulator -directory $compiled_lib_dir -verbose} result]} {
    puts "Error during library compilation: $result"
    puts "Make sure you have enough disk space and appropriate permissions."
    return 1
}

# Attempt to update project to use these libraries
if {[catch {current_project} result]} {
    puts "No current project found. You'll need to manually set the compiled library path when you open your project."
    puts "Use: set_property compxlib.compiled_library_dir $compiled_lib_dir \[current_project\]"
} else {
    if {[catch {set_property compxlib.compiled_library_dir $compiled_lib_dir [current_project]} err]} {
        puts "Warning: Could not update project properties: $err"
        puts "You may need to manually set the compiled library path in Project Settings."
    } else {
        puts "Project successfully updated to use compiled libraries"
    }
}

puts "========================================================="
puts "Simulation libraries compilation complete!"
puts "Libraries location: $compiled_lib_dir"
puts ""
puts "The following warnings should now be resolved:"
puts "  [Vivado 12-13277] Compiled library path does not exist"
puts ""
puts "You can also add this manually to your project settings:"
puts "  Project Settings > Simulation > Compiled Library Location"
puts "========================================================="
