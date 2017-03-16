import numpy as np
import csv
import json
import argparse
import pickle
ap = argparse.ArgumentParser()
ap.add_argument("-m", "--method", help="vote Method to learn from")
ap.add_argument("-r", "--row", help="data row joined by comma")
ap.add_argument("-f", "--filename", help="filename of dataset")
args = vars(ap.parse_args())
models = pickle.loads(open(args["method"]+".pkl").read())
def read_csv(filename):
  dataset = []
  i = 0
  with open(filename, 'rb') as f:
      reader = csv.reader(f)
      for row in reader:
        if i != 0:  
          dataset.append([float(el) for el in row])
        i += 1
  return dataset

if args["row"] is not None:
  predictions = []
  for m in models:
    prediction = float(m.predict([float(el) for el in args["row"].split(',')]))
    if prediction > 0.5:
      prediction = 1
    else:
      prediction = 0
    predictions.append(prediction)
  print (sum(predictions)/float(len(predictions)))
elif args["filename"] is not None:
  dataset = read_csv(args["filename"])
  all_predictions = []
  for m in models:
    all_predictions.append(m.predict(dataset))
  final_predictions = []
  for prediction_row in np.array(all_predictions).transpose():
    predicted = []
    for el in prediction_row:
      if el > 0.5:
        predicted.append(1)
      else:
        predicted.append(0)
    final_predictions.append(sum(predicted)/float(len(predicted)))
  print(json.dumps(final_predictions))