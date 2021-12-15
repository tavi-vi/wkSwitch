This is a simple utility that switches sway/i3 workspaces similar to how xmonad does. It has no build time dependencies other than the `musl` C library. It can be built with the GNU C Library, but why would you? The goal of this program is to just be as fast as possible, and it is. Static linking with musl furthers that goal, even if it is excessive.

# Usage
To use it, just invoke it with the workspace you want to switch to, like `switch 2`, or `switch web`, and it will switch to it if the desired workspace is not displayed on any output, or swap your current workspace with the desired one if the desired workspace is already open on another output.

# Bugs
It doesn't support switching to workspaces using their number ID, but sway treats string workspace identifiers as numerical identifiers if they are numbers, so I'm not aware of any problems it causes. `switch 2` will still switch to the numerical second workspace, as far as I can tell.
