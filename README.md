# Stop Sign Project

A website and rake task meant to run on a Raspberry Pi to automatically detect movement within a fixed frame via a webcam, and a lightweight way to scan through records of movement in order to train a machine learner in order to get people to get off my lawn.

To run:

* sudo mongod --dbpath=/path/to/db
* rake record_data
* rvmsudo rackup -p 80 -o 0.0.0.0
* rake analyze_data
* rake summarize_data

Personally, my Pi has these in a script that fires on startup - for some reason, my webcam will fail to take pictures from time to time, so I just have it reboot and have this startup tmux script in `~/tmux_start.sh`:

```
#!/bin/bash
sleep 60
SESSIONNAME="stop_sign"
cd /media/pi/STICK/stop_sign_project
tmux new-session -d
tmux neww
tmux neww
tmux neww
tmux neww
tmux send-keys -t "1" C-z 'sudo mongod --dbpath=/media/pi/STICK/data' Enter
tmux send-keys -t "2" C-z 'rvmsudo rackup -p 80 -o 0.0.0.0' Enter
tmux send-keys -t "3" C-z 'rake record_data' Enter
tmux send-keys -t "4" C-z 'rake analyze_data' Enter
tmux send-keys -t "4" C-z 'rake summarize_data' Enter
````
## Installation

In order to make this project work on your Raspberry Pi without any issues, you need to 1. install the OS from the [base install](https://www.raspberrypi.org/documentation/installation/installing-images/) on Raspberry Pi's site and 2. Follow [these steps](https://github.com/Tes3awy/OpenCV-3.2.0-Compiling-on-Raspberry-Pi) to install the right CV libraries. You could probably get away doing (2) without (1), but I wasn't able to, with whatever default OS I had on my Pi when I bought it. 