#ffmpeg -i /media/pi/STICK/videos/#{time}.mp4 -vcodec mpeg4 -acodec ac3 /media/pi/STICK/videos/#{time}.avi
#ffmpeg -i IMG_3663.m4v -f avi -b 2048k -ab 160k -ar 44100 IMG_3663.avi
#ffmpeg -i IMG_3664.m4v -f avi -b 2048k -ab 160k -ar 44100 IMG_3664.avi
#ffmpeg -i IMG_3665.m4v -f avi -b 2048k -ab 160k -ar 44100 IMG_3665.avi
#ffmpeg -i IMG_3666.m4v -f avi -b 2048k -ab 160k -ar 44100 IMG_3666.avi
# USAGE
# python motion_detector.py
# python motion_detector.py --video videos/example_01.mp4

# import the necessary packages
import copy
from astral import Astral
import pytz
from datetime import datetime
import argparse
import imutils
import time
import cv2
import numpy as np
from time import gmtime, strftime
import json
from itertools import islice
import hashlib
import pickle
ap = argparse.ArgumentParser()
ap.add_argument("-v", "--video", help="path to the video file")
ap.add_argument("-a", "--min-area", type=int, default=5000, help="minimum area size")
ap.add_argument("-t", "--time", type=int, default=1489182399, help="UTC Time")
args = vars(ap.parse_args())
time_of_video = datetime.fromtimestamp(int(args["time"])).replace(tzinfo=pytz.timezone('UTC')).astimezone(pytz.timezone('America/New_York'))
config = json.loads(open("config.json").read())
#car_presence_model = pickle.loads(open("car_presence_model.pkl").read())
#{'fp': 8, 'tn': 402, 'tp': 179, 'fn': 50}
#0.909233176839

def get_daylight():
    a = Astral()
    sun_info = a["Boston"].sun(date=time_of_video, local=True)
    return sun_info['sunrise'] < time_of_video and sun_info['sunset'] > time_of_video

def currently_daylight(last_check, is_daylight):
  if (datetime.now(pytz.timezone('America/New_York'))-last_check).seconds < 60*60*10:
    return is_daylight
  else:
    is_daylight = get_daylight()
    last_check = datetime.now(pytz.timezone('America/New_York'))
    return is_daylight

def assess_stop(current_obj):
  x_pos = [el[0] for el in current_obj]
  stopped_frame_points = len(np.where(np.array([abs(np.mean(el)) for el in window([j-i for i, j in zip(x_pos[:-1], x_pos[1:])], 8)]) < 1)[0])
  disallowed_time = False
  if datetime.today().weekday() != 6 and float(time.strftime("%H")) >= 15 and float(time.strftime("%H")) < 19:
    disallowed_time = True
  if stopped_frame_points < 3:
    return (True, np.mean([j-i for i, j in zip(x_pos[:-1], x_pos[1:])]), time_of_video.strftime("%Y-%m-%d %H:%M:%S %Z%z"), disallowed_time, stopped_frame_points)
  else:
    return (False, np.mean([j-i for i, j in zip(x_pos[:-1], x_pos[1:])]), time_of_video.strftime("%Y-%m-%d %H:%M:%S %Z%z"), disallowed_time, stopped_frame_points)

def window(seq, n=2):
  it = iter(seq)
  result = tuple(islice(it, n))
  if len(result) == n:
    yield result
  for elem in it:
    result = result[1:] + (elem,)
    yield result

def centroid(x,y,w,h):
  x_cen = x+w / 2
  y_cen = y+h / 2
  return [x_cen, y_cen]

is_daylight = get_daylight()
last_check = datetime.now(pytz.timezone('America/New_York'))

all_dists = []
areas = []
# construct the argument parser and parse the arguments
obj_history = []
current_objs = []
# if the video argument is None, then we are reading from webcam
if args.get("video", None) is None:
  camera = cv2.VideoCapture(0)
  time.sleep(0.25)
# otherwise, we are reading from a video file
else:
  camera = cv2.VideoCapture(args["video"])

# initialize the first frame in the video stream
firstFrame = None
#fgbg = cv2.createBackgroundSubtractorMOG()
#fgbg = cv2.bgsegm()
fgbg = cv2.createBackgroundSubtractorMOG2()
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(3,3))
frames = []
current_objs_full = []
# loop over the frames of the video
while True:
  # grab the current frame and initialize the occupied/unoccupied
  # text
  (grabbed, frame) = camera.read()
  text = "0"
  #time.sleep(0.0333)
  # if the frame could not be grabbed, then we have reached the end
  # of the video
  if not grabbed:
    #print np.mean(areas)
    break
  frame = imutils.resize(frame, width=500)
  fgmask = fgbg.apply(frame)
  fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
  bayes_thresh = cv2.threshold(fgmask, 25, 255, cv2.THRESH_BINARY)[1]
  bayes_thresh = cv2.dilate(bayes_thresh, None, iterations=2)
  (_, cnts, _) = cv2.findContours(bayes_thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
  # loop over the contours
  latest_cs = []
  for c in cnts:
    # if the contour is too small, ignore it
    min_area = 400#args["min_area"]
    #if not currently_daylight(last_check, is_daylight):
    #  min_area = 1500
    if cv2.contourArea(c) < min_area:
      continue
    # compute the bounding box for the contour, draw it on the frame,
    # and update the text
    (x, y, w, h) = cv2.boundingRect(c)
    #if float(h)/w > 0.80:
    #  continue
    center = centroid(x,y,w,h)
    inside = False
    if center[0] > 50 and center[0] < 450 and center[1] > 100 and center[1] < 200:
      inside = True
    if not inside:
      continue
    latest_cs.append(center)
    if len(current_objs) == 0:
      current_objs.append([centroid(x,y,w,h)])
      current_objs_full.append([[x,y,w,h]])
    else:
      dists = []
      for obj in current_objs:
        dists.append((centroid(x,y,w,h)[0] - obj[-1][0])**2 + (centroid(x,y,w,h)[1] - obj[-1][1])**2)
      all_dists.append(dists)
      min_dist = sorted(dists)[0]
      #print "MIN DIST"
      #print min_dist
      if min_dist < 600:
        current_objs[dists.index(min_dist)].append(centroid(x,y,w,h))
        current_objs_full[dists.index(min_dist)].append([x,y,w,h])
      else:
        current_objs.append([centroid(x,y,w,h)])
        current_objs_full.append([[x,y,w,h]])
    #cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
    text = str(len(current_objs))
  cv2.rectangle(frame, (100, 100), (350, 200), (255, 0, 0), 2)
  new_current_objs = []
  new_current_objs_full = []
  if len(current_objs) > 0:
    frames.append(frame)
  if len(frames) > 150:
    frames = frames[-150:]
  #print current_objs
  for ii,current_obj in enumerate(current_objs):
    if len(latest_cs) == 0:#with webcam in final place, only write this if the box is now pressed against the left of the window right before we lose the car, ELSE append to current_obj last known position
      if len(current_obj) > 10:
        #if currently_daylight(last_check, is_daylight):
          with open(config["project_dir"]+"stop_sign.log", "a") as myfile:
            h = hashlib.new('ripemd160')
            h.update(json.dumps(assess_stop(current_obj)))
            stop_id = h.hexdigest()
            myfile.write(json.dumps({"time": args["time"], "written_before_stop": True, "stop_id": stop_id, "daylight": is_daylight, "assessment": assess_stop(current_obj), "drive_data_full": current_objs_full[ii], "drive_data": current_obj, "frame_count": len(current_obj)})+"\r\n")
            max_prev = len(current_obj)
            if max_prev > 145:
              max_prev = 145
            fps=30
            fourcc = cv2.VideoWriter_fourcc(*'XVID')
            out = cv2.VideoWriter(config["project_dir"]+'cases/'+str(args["time"])+"_"+stop_id+".avi",fourcc, 20.0, (frames[0].shape[1],frames[0].shape[0]))
            for i,ff in enumerate(frames[-max_prev:]):
              ff = copy.deepcopy(ff)
              cv2.circle(ff, (current_obj[i][0], current_obj[i][1]), 3, (0, 255, 0))
              out.write(ff)
            out.release()
    else:
      #print latest_cs
      min_dist = sorted([(c[0]-current_obj[-1][0])**2+(c[1]-current_obj[-1][1])**2 for c in latest_cs])[0]
      if min_dist > 600 and len(current_obj) > 10:
        #if currently_daylight(last_check, is_daylight):
          with open(config["project_dir"]+"stop_sign.log", "a") as myfile:
            h = hashlib.new('ripemd160')
            h.update(json.dumps(assess_stop(current_obj)))
            stop_id = h.hexdigest()
            myfile.write(json.dumps({"time": args["time"], "written_before_stop": True, "stop_id": stop_id, "daylight": is_daylight, "assessment": assess_stop(current_obj), "drive_data_full": current_objs_full[ii], "drive_data": current_obj, "frame_count": len(current_obj)})+"\r\n")
            max_prev = len(current_obj)
            if max_prev > 145:
              max_prev = 145
            fps=30
            fourcc = cv2.VideoWriter_fourcc(*'XVID')
            out = cv2.VideoWriter(config["project_dir"]+'cases/'+str(args["time"])+"_"+stop_id+".avi",fourcc, 20.0, (frames[0].shape[1],frames[0].shape[0]))
            for i,ff in enumerate(frames[-max_prev:]):
              cv2.circle(ff, (current_obj[i][0], current_obj[i][1]), 3, (0, 255, 0))
              out.write(ff)
            out.release()
      else:
        new_current_objs.append(current_obj)
        new_current_objs_full.append(current_objs_full[ii])
  current_objs = new_current_objs
  current_objs_full = new_current_objs_full
  # draw the text and timestamp on the frame
  #cv2.putText(frame, "Current Cars: {}".format(text), (10, 20),
  #  cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
  #cv2.putText(frame, datetime.now().strftime("%A %d %B %Y %I:%M:%S%p"),
  #  (10, frame.shape[0] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (0, 0, 255), 1)
  # show the frame and record if the user presses a key
  #cv2.imshow("CV", fgmask)
  #cv2.imshow("Raw Input", frame)
  key = cv2.waitKey(1) & 0xFF
  # if the `q` key is pressed, break from the lop
  if key == ord("q"):
    break

# cleanup the camera and close any open windows
camera.release()
