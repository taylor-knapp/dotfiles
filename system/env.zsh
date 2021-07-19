export EDITOR='storm'

# Set defaults for using `less`.
# -R displays escaped characters like '/' correctly
# -M displays lines and percentage (once the full buffer has been loaded).
# +Gg adds initial commands to execute. G loads to the end of the file, and g jumps back to the beginning.
#   This trick always shows the total lines and percentage while scrolling, but can slowdown loads for large buffers.
#   To deal with slow load times, you can change the initial commands to just start at the beginning with `less +g.
export LESS='-RM +Gg'