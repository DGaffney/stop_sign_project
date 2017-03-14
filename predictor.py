import itertools
from sklearn.linear_model import Perceptron
from sklearn import linear_model
import random
from sklearn.neighbors import KNeighborsClassifier
import itertools
from scipy import stats
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import GaussianNB
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import VotingClassifier
from sklearn.ensemble import AdaBoostClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn import ensemble
from sklearn.svm import SVC
from sklearn import svm
from sklearn import linear_model
from sklearn import preprocessing
from sklearn import gaussian_process
from sklearn.neighbors.nearest_centroid import NearestCentroid
from sklearn import tree
from sklearn.ensemble import GradientBoostingRegressor
import numpy as np
import csv
from sklearn.neighbors import NearestNeighbors
from sklearn.linear_model import SGDClassifier
from os import listdir
from os.path import isfile, join
import numpy as np
import csv
models = [
Perceptron(fit_intercept=False, n_iter=10, shuffle=False),
Perceptron(fit_intercept=False, n_iter=3, shuffle=False),
Perceptron(fit_intercept=False, n_iter=5, shuffle=False),
Perceptron(fit_intercept=True, n_iter=10, shuffle=False),
Perceptron(fit_intercept=True, n_iter=3, shuffle=False),
Perceptron(fit_intercept=True, n_iter=5, shuffle=False),
linear_model.Ridge(alpha = .5),
SVC(kernel="linear", max_iter=1000), 
SVC(kernel="poly", degree=3, max_iter=1000), 
SVC(kernel="rbf", max_iter=1000), 
SVC(kernel="sigmoid", max_iter=1000),
svm.LinearSVC(),
svm.SVR(),
SGDClassifier(loss="hinge", penalty="l2"),
SGDClassifier(loss="log"),
KNeighborsClassifier(n_neighbors=2),
KNeighborsClassifier(n_neighbors=6),
KNeighborsClassifier(n_neighbors=10),
NearestCentroid(), 
RandomForestClassifier(n_estimators=2), 
RandomForestClassifier(n_estimators=10), 
RandomForestClassifier(n_estimators=18), 
RandomForestClassifier(criterion="entropy", n_estimators=2), 
RandomForestClassifier(criterion="entropy", n_estimators=10), 
RandomForestClassifier(criterion="entropy", n_estimators=18), 
AdaBoostClassifier(n_estimators=50), 
AdaBoostClassifier(n_estimators=100), 
AdaBoostClassifier(learning_rate= 0.5, n_estimators=50), 
AdaBoostClassifier(learning_rate= 0.5, n_estimators=100), 
LogisticRegression(random_state=1), 
RandomForestClassifier(random_state=1), 
GaussianNB(),
linear_model.LinearRegression(),
linear_model.Lasso(alpha = 0.1),
linear_model.Lasso(alpha = 0.5),
tree.DecisionTreeClassifier(),
tree.DecisionTreeRegressor(),
linear_model.ElasticNet(alpha=0.1, l1_ratio=0.7),
linear_model.ElasticNet(alpha=0.5, l1_ratio=0.7),
linear_model.ElasticNet(alpha=0.1, l1_ratio=0.2),
linear_model.ElasticNet(alpha=0.5, l1_ratio=0.2),
# gaussian_process.GaussianProcess(theta0=1e-2, thetaL=1e-4, thetaU=1e-1),
linear_model.RidgeCV(alphas=[0.1, 1.0, 10.0]),
linear_model.LassoLars(alpha=0.1),
linear_model.LassoLars(alpha=0.5),
linear_model.BayesianRidge(),
ensemble.GradientBoostingClassifier(**{'n_estimators': 1000, 'max_leaf_nodes': 4, 'max_depth': None, 'random_state': 2, 'min_samples_split': 5, 'learning_rate': 1.0, 'subsample': 1.0}),
GradientBoostingRegressor(n_estimators=100, learning_rate=0.1, max_depth=1, random_state=0, loss='ls')]

def produce_ensemble_guesses_restricted(all_guesses, fold_labels, clfs, included_clfs):
  success = 0
  count = 0.0
  conmat = {'fp': 0, 'fn': 0, 'tp': 0, 'tn': 0}
  clf_indices = []
  for clf in clfs:
    if str(clf) in included_clfs:
      clf_indices.append(1)
    else:
      clf_indices.append(0)
  sub_guesses = [g for i,g in enumerate(all_guesses) if clf_indices[i] == 1]
  aggregate_guesses = [np.mean(el) for el in np.matrix(sub_guesses).transpose().tolist()]
  for pair in np.matrix([aggregate_guesses, fold_labels]).transpose().tolist():
    count += 1
    if pair[0] > 0.5 and pair[1] == 1:
      conmat['tp'] += 1
      success += 1
    elif pair[0] > 0.5 and pair[1] == 0:
      conmat['fp'] += 1
    elif pair[0] <= 0.5 and pair[1] == 1:
      conmat['fn'] += 1
    elif pair[0] <= 0.5 and pair[1] == 0:
      conmat['tn'] += 1
      success += 1
  return conmat, success/count

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

def run_ensemble_binary(filename, models, str_columns, keys_included):
  keys, dataset, labels = dataset_array_form_from_csv(filename, str_columns, keys_included)
  folds = generate_folds(dataset, labels, fold_count=10)
  folded_results = []
  conmats = []
  guesses = []
  fold_labels = [fold["test_labels"] for fold in folds]
  for clf in models:
    this_conmat = {'fp': 0, 'fn': 0, 'tp': 0, 'tn': 0}
    this_guess = []
    for fold in folds:
      clf.fit(np.array(fold['train_set']), np.array(fold['train_labels']))
      predictions = list(clf.predict(fold["test_set"]))
      for prediction in predictions:
        this_guess.append(prediction)
      for pair in np.matrix([predictions, fold["test_labels"]]).transpose().tolist():
        if pair[0] >= 0.5 and pair[1] == 1:
          this_conmat['tp'] += 1
        elif pair[0] >= 0.5 and pair[1] == 0:
          this_conmat['fp'] += 1
        elif pair[0] < 0.5 and pair[1] == 1:
          this_conmat['fn'] += 1
        elif pair[0] < 0.5 and pair[1] == 0:
          this_conmat['tn'] += 1
    conmats.append(this_conmat)
    guesses.append(this_guess)
  return conmats, guesses, [item for sublist in fold_labels for item in sublist], models

def dataset_array_form_from_csv(filename, str_columns, keys_included):
  keys = []
  dataset = []
  labels = []
  bad_rows = []
  with open(filename, 'rb') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    i = -1
    for row in reader:
      i += 1
      if keys_included and i == 0:
        keys = row
      else:
        # if '' not in row:
        record = []
        for j,val in enumerate(row):
          if j not in str_columns:
            parsed_val = None
            if val == '':
              parsed_val = None
            else:
              try:
                parsed_val = float(val)
              except ValueError:
                parsed_val = np.random.rand()
            if j == 0:
              labels.append(parsed_val)
            else:
              record.append(parsed_val)
        dataset.append(record)
  return keys, dataset, labels

def generate_folds(dataset, labels, fold_count):
	folded = []
	for i in range(fold_count):
		folded.append({'test_set': [], 'train_set': [], 'test_labels': [], 'train_labels': []})
	i = 0
	all_counts = range(fold_count)
	for i in range(len(dataset)):
		mod = i%fold_count
		folded[mod]['test_set'].append(dataset[i])
		folded[mod]['test_labels'].append(labels[i])
		for c in all_counts:
			if c != mod:
				folded[c]['train_set'].append(dataset[i])
				folded[c]['train_labels'].append(labels[i])
	return folded

all_conmats, all_guesses, fold_labels, used_models = run_ensemble_binary("machine_learning_human_votes_car_present.csv", models, [], True)
keys, dataset, labels = dataset_array_form_from_csv("machine_learning_human_votes_car_present.csv", [], True)
current_best_fn = [[], 0]
current = 0
improvement_count = 0
best_conmat = {}

while current < 10000000:
  for i in range(len(models)):
    print i
    for h in itertools.combinations(models, i+1):
      #h = [random.choice(models) for m in np.arange(int(np.random.random()*len(models)/2))]
      conmat, pct = produce_ensemble_guesses_restricted(all_guesses, fold_labels, models, [str(m) for m in h])
      # current += 1
      if current_best_fn[-1] < pct:
        current = 0
        improvement_count += 1
        current_best_fn = [h, pct]
        best_conmat = conmat
        print conmat
        print current_best_fn[-1]
      try:
        h = [random.choice(models) for m in np.arange(int(np.random.random()*len(models)))]
        conmat, pct = produce_ensemble_guesses_restricted(all_guesses, fold_labels, models, [str(m) for m in h])
        # current += 1
        if current_best_fn[-1] < pct:
          current = 0
          improvement_count += 1
          current_best_fn = [h, pct]
          best_conmat = conmat
          print conmat
          print current_best_fn[-1]
      except:
        print "whoops"

best_models = current_best_fn[0]
guesses_for_file = []
for clf in best_models:
  guesses_for_file.append(clf.predict(read_csv("testing.csv")))

non_human_percent = [np.mean(el) > 0.5 for el in np.matrix(guesses_for_file).transpose()].count(True)/float(len(guesses_for_file[0]))
human_percent = 1-non_human_percent
adjusted_non_human_percent = non_human_percent-non_human_percent*(best_conmat['fp']/float(best_conmat['fp']+best_conmat['tp']))+non_human_percent*(best_conmat['fn']/float(best_conmat['fn']+best_conmat['tn']))
adjusted_human_percent = human_percent+human_percent*(best_conmat['fp']/float(best_conmat['fp']+best_conmat['tp']))-human_percent*(best_conmat['fn']/float(best_conmat['fn']+best_conmat['tn']))
print("Minimum Non Clearly Human Percent")
print(sorted([non_human_percent, adjusted_non_human_percent])[0])
print("Maximum Non Clearly Human Percent")
print(sorted([non_human_percent, adjusted_non_human_percent])[1])
print("Minimum Clearly Human Percent")
print(sorted([human_percent, adjusted_human_percent])[0])
print("Maximum Clearly Human Percent")
print(sorted([human_percent, adjusted_human_percent])[1])