#!/bin/bash

# Start a new tmux session in the background
tmux new-session -d -s SlimbookBatterySession

# In the tmux session, run powertop in auto-tune mode
tmux send-keys -t SlimbookBatterySession "sudo powertop --auto-tune" Enter

# Allow some time for the auto-tune to complete
sleep 5

# Start slimbookbattery without closing it when the terminal closes
tmux send-keys -t SlimbookBatterySession "slimbookbattery" Enter

# Optionally, attach to the tmux session if you want to see the output
# tmux attach-session -t SlimbookBatterySession

# Inform the user
echo "slimbookbattery has been started in a tmux session named SlimbookBatterySession."
echo "You can attach to this session by running 'tmux attach-session -t SlimbookBatterySession'."
echo "You can close this terminal now without affecting slimbookbattery."
