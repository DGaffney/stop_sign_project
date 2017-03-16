import argparse
import pickle
ap = argparse.ArgumentParser()
ap.add_argument("-m", "--method", help="vote Method to learn from")
ap.add_argument("-r", "--row", help="data row joined by comma")
args = vars(ap.parse_args())
models = pickle.loads(open(args["method"]+".pkl").read())
predictions = []
for m in models:
  prediction = float(m.predict([float(el) for el in args["row"].split(',')]))
  if prediction > 0.5:
    prediction = 1
  else:
    prediction = 0
  predictions.append(prediction)

print(sum(predictions)/float(len(predictions)))