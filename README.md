# Stop Sign Project

A website and rake task meant to run on a Raspberry Pi to automatically detect movement within a fixed frame via a webcam, and a lightweight way to scan through records of movement in order to train a machine learner in order to get people to get off my lawn.

To run:

* sudo mongod --dbpath=/path/to/db
* rake record_data
* rvmsudo rackup -p 80 -o 0.0.0.0