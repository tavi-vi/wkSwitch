This is a simple utility that switches sway/i3 workspaces similar to how xmonad does. It has no build time dependencies other than the Zig 0.9.1 compiler and standard library. The goal of this program is to just be as fast as possible, and it is. The static linking and zero-cost abstractions of Zig furthers that goal, even if it is excessive.

# Usage
To use it, just invoke it with the workspace you want to switch to, like `switch 2`, or `switch web`, and it will switch to it if the desired workspace is not displayed on any output, or swap your current workspace with the desired one if the desired workspace is already open on another output.

# Building
You need the Zig 0.9.1 compiler in your environment, and you just need to run `make`. The compiled executable will be available in `./zig-out/bin/`, copy that to somewhere in your PATH, or reference the absolute path from your sway/i3 config. Alternatively, you can just build it using the nix flake included, by running `nix build` in the respository, or including it as an input to a home-manager flake.

# Bugs
It doesn't support switching to workspaces using their number ID, but sway treats string workspace identifiers as numerical identifiers if they are numbers, so I'm not aware of any problems it causes. `switch 2` will still switch to the numerical second workspace, as far as I can tell.
