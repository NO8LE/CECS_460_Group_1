# SystemC Installation Guide for macOS

This guide will help you install and set up SystemC on your macOS system and configure Visual Studio Code to work with it.

## Step 1: Clone SystemC from GitHub

1. Open Terminal
2. Navigate to a directory where you want to download the source code
3. Clone the official SystemC repository:
   ```bash
   git clone https://github.com/accellera-official/systemc.git
   ```
4. Navigate into the cloned repository:
   ```bash
   cd systemc
   ```
5. Check out a stable release tag (recommended):
   ```bash
   # List available tags
   git tag -l
   
   # Check out a specific version (e.g., 2.3.3)
   git checkout -b systemc-2.3.3 systemc-2.3.3
   ```
   This ensures you're using a stable, tested version rather than potentially unstable development code.

## Step 2: Build and Install SystemC

### For Apple Silicon Macs (M1/M2/M3, arm64/aarch64)

If you're using an Apple Silicon Mac, the traditional configure script will report "sorry...architecture not supported". You must use CMake instead:

1. Create a directory where you want to install SystemC:
   ```bash
   mkdir -p ~/systemc-2.3.3
   ```

2. Install CMake if you don't have it:
   ```bash
   brew install cmake
   ```

3. Configure the build specifically for arm64:
   ```bash
   mkdir build
   cd build
   cmake .. -DCMAKE_CXX_STANDARD=11 -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_INSTALL_PREFIX=$HOME/systemc-2.3.3 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
   ```

4. Build and install:
   ```bash
   make
   make install
   ```

### For Intel Macs (x86_64)

1. Create a directory where you want to install SystemC:
   ```bash
   mkdir -p ~/systemc-2.3.3
   ```

2. Configure the build:
   ```bash
   mkdir build
   cd build
   cmake .. -DCMAKE_CXX_STANDARD=11 -DCMAKE_INSTALL_PREFIX=$HOME/systemc-2.3.3
   ```
   
   Note: If you don't have CMake installed, you can install it with Homebrew:
   ```bash
   brew install cmake
   ```
   
   If you prefer to use the traditional build system instead of CMake:
   ```bash
   ../configure --prefix=$HOME/systemc-2.3.3
   ```
   
3. Build and install SystemC:
   ```bash
   make
   make install
   ```

## Step 3: Set Up Environment Variables

Add the following to your shell profile file (`~/.zshrc` for newer macOS versions or `~/.bash_profile` for older versions):

```bash
# Set the SystemC home directory
export SYSTEMC_HOME=$HOME/systemc-2.3.3

# For CMake build, the libraries are in lib/
export DYLD_LIBRARY_PATH=$SYSTEMC_HOME/lib:$DYLD_LIBRARY_PATH

# For configure/make build, the libraries are in lib-macosx/
# Uncomment this line instead if using the traditional build method
# export DYLD_LIBRARY_PATH=$SYSTEMC_HOME/lib-macosx:$DYLD_LIBRARY_PATH
```

Apply the changes:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

Note: You should update the Makefile's SYSTEMC_LIBDIR path accordingly if you're using CMake build:
```
# For CMake build
SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib
```

## Step 4: Configure Visual Studio Code

### Install Required VS Code Extensions

1. Open VS Code
2. Go to Extensions (or press `Cmd+Shift+X`)
3. Install:
   - C/C++ extension by Microsoft
   - C/C++ Extension Pack

### Configure VS Code for SystemC

1. Create a `.vscode` folder in your project directory if it doesn't exist already
2. Create a file named `c_cpp_properties.json` in the `.vscode` folder with the following content:

```json
{
    "configurations": [
        {
            "name": "Mac",
            "includePath": [
                "${workspaceFolder}/**",
                "${env:SYSTEMC_HOME}/include"
            ],
            "defines": [],
            "macFrameworkPath": [
                "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks"
            ],
            "compilerPath": "/usr/bin/clang++",
            "cStandard": "c17",
            "cppStandard": "c++11",
            "intelliSenseMode": "macos-clang-x64"
        }
    ],
    "version": 4
}
```

3. Create a file named `tasks.json` in the `.vscode` folder to enable building from VS Code:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "make all",
            "type": "shell",
            "command": "make",
            "args": ["all"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "make clean",
            "type": "shell",
            "command": "make",
            "args": ["clean"],
            "problemMatcher": []
        },
        {
            "label": "run task1",
            "type": "shell",
            "command": "make",
            "args": ["run_task1"],
            "problemMatcher": []
        },
        {
            "label": "run task2",
            "type": "shell",
            "command": "make",
            "args": ["run_task2"],
            "problemMatcher": []
        },
        {
            "label": "run task3",
            "type": "shell",
            "command": "make",
            "args": ["run_task3"],
            "problemMatcher": []
        }
    ]
}
```

## Step 5: Building and Running with Make

Now you can use the Makefile that's already been created to build and run your SystemC projects:

1. Open Terminal and navigate to your project directory
2. Verify that your environment variable is set correctly:
   ```bash
   echo $SYSTEMC_HOME
   ```
3. Build all tasks:
   ```bash
   make all
   ```
4. Run a specific task:
   ```bash
   make run_task1
   ```

## Step 6: Building from VS Code

After setting up the task configurations:

1. Press `Cmd+Shift+B` to build (runs the default build task)
2. To run other tasks:
   - Press `Cmd+Shift+P`
   - Type "Run Task" and select it
   - Choose the task you want to run (e.g., "run task1")

## Troubleshooting

### If you see "systemc.h file not found" errors:

1. Verify your SystemC_HOME path is correct:
   ```bash
   echo $SYSTEMC_HOME
   ```
2. Check that the include directory exists:
   ```bash
   ls -la $SYSTEMC_HOME/include
   ```
3. Make sure VS Code is recognizing your environment variables by restarting VS Code after setting the variables

### Library Path Issues

If you encounter runtime errors about missing libraries:

```bash
# For CMake build (both Apple Silicon and Intel Macs)
export DYLD_LIBRARY_PATH=$SYSTEMC_HOME/lib:$DYLD_LIBRARY_PATH

# For configure/make build (Intel Macs only)
export DYLD_LIBRARY_PATH=$SYSTEMC_HOME/lib-macosx:$DYLD_LIBRARY_PATH
```

This is macOS's equivalent to LD_LIBRARY_PATH and may be needed for runtime linking.

### Apple Silicon Troubleshooting

If you continue to experience issues with Apple Silicon, you can try these alternatives:

1. **Use Rosetta 2 to build in x86_64 mode**:
   ```bash
   arch -x86_64 bash
   # Then proceed with normal build steps within this shell
   ```

2. **Build with specific Apple Silicon flags**:
   ```bash
   cd build
   cmake .. -DCMAKE_CXX_STANDARD=11 -DCMAKE_CXX_FLAGS="-arch arm64" -DCMAKE_INSTALL_PREFIX=$HOME/systemc-2.3.3
   ```

3. **Use a more recent SystemC development branch**:
   Some newer branches may have better support for Apple Silicon.

### Compiler Errors

If you encounter compiler errors related to C++ standards, you may need to explicitly set the C++ standard in the Makefile. Edit the CXXFLAGS line to include the standard you need:

```
CXXFLAGS = -std=c++11 -Wall -I$(SYSTEMC_INCLUDE)