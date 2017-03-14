import pytz
from imgurpython import ImgurClient
import json
import argparse
from datetime import datetime
ap = argparse.ArgumentParser()
ap.add_argument("-g", "--gif", help="path to the GIF file")
args = vars(ap.parse_args())
config = json.loads(open("config.json").read())
client = ImgurClient(config["imgur_client_id"], config["imgur_client_secret"], config["imgur_access_token"], config["imgur_refresh_token"])
time_of_video = datetime.fromtimestamp(int(int(args["gif"].split("/")[-1].split("_")[0]))).replace(tzinfo=pytz.timezone('UTC')).astimezone(pytz.timezone('America/New_York'))
title = time_of_video.strftime("The view on %A, %B %d %Y (%H:%M %p)")
#img = client.upload_from_path(args['gif'], config={"title": title, "album": config["imgur_album_id"]}, anon=False)
img = client.upload_from_path(args['gif'], config={"title": title}, anon=False)

print img['link']
