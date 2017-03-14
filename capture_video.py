from datetime import datetime
from __future__ import print_function
from imutils.video import WebcamVideoStream
from imutils.video import FPS
import argparse
import imutils
import cv2
import time
vs = WebcamVideoStream(src=0).start()
frames = []
for el in range(160):
  time.sleep(0.03333)
  frames.append(vs.read())

start_time = datetime.now()
i = 0
while len(frames) < 1000:
  frame = vs.read()
  #if False in (frames[-1] == frame):
  time.sleep(0.03333)
  frames.append(frame)

end_time = datetime.now()
for i,frame in enumerate(frames):
  cv2.imwrite("/media/pi/STICK/pics/frame_"+str(i)+".jpg", cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA))

print(len(frames)/(end_time-start_time).seconds)

