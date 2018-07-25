import os
#import wget
import shutil
import math
import matplotlib as mpl
import matplotlib.pyplot as plt

# obtain market data
def acquire(sym,interval):

	if not os.path.isfile("../data/%s.csv" %sym):
		shutil.copy("../QSTK-0.2.8/QSTK/QSData/Yahoo/%s.csv" %sym, "../data")
# --------------------------------------------------------------------------------------------
#
#       If downloading from yahoo:
#
#       down = wget.download("http://real-chart.finance.yahoo.com/table.csv?s=%s" %sym)
#       shutil.move(down,"../data/%s.csv" %sym)
#
# --------------------------------------------------------------------------------------------
	data   = open("../data/%s.csv" %sym,'r')
	stream = data.read()
	data.close()

	field  = 7
	entry  = ""
	val    = []
	matrix = []

	for ch in stream:
		entry = entry + ch
		if ch==',' or ch=='\n':
			if len(entry)>1:
				val.append(entry[:-1])
			entry = ""
		if len(val)>=field:
			if interval[1] >= val[0] >= interval[0]:
				matrix.append(val)
			val = []

	matrix.sort()
	return matrix

def plot(label,matrix,mean,std,rat,delta,period):

	x  = []
	y  = [[]for l in range(4)]
	Y  = []
	hd = 0
	hs = [-2,2]
	xl = [-10,period-delta+10]

	mpl.rc('text', color='#C8A078')
	mpl.rc('figure', facecolor='black', edgecolor='black')
	mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
	mpl.rc('xtick', color='#C8A078')
	mpl.rc('ytick', color='#C8A078')
	plt.tick_params(bottom=False, top=False, left=False, right=False)

	plt.figure(1)
	plt.subplot(211)
	for i in range(delta-1,period):
		x.append(float(i-delta+1))
		y[0].append(mean[i])
		y[1].append(mean[i] - std[i])
		y[2].append(mean[i] + std[i])
		y[3].append(rat[i])
		Y.append(float(matrix[i][6]))
	plt.plot(x, Y,    color='#004040', linewidth=2)
	plt.plot(x, y[0], color='#F5A078', linewidth=2)
	plt.plot(x, y[1], color='#640064', linewidth=2)
	plt.plot(x, y[2], color='#640064', linewidth=2)
	plt.xlim(xl)
	plt.title("%s Stockchart: Jan 2008 to Dec 2009" %label, fontsize=25)
	plt.xticks(fontsize=20)
	plt.yticks(fontsize=20)
	plt.ylabel("Price", fontsize=25)

	plt.subplot(212)
	plt.hlines(hs, xl[0], xl[1], linestyles='solid',  color='#F5A078', linewidth=1)
	plt.hlines(hd, xl[0], xl[1], linestyles='dotted', color='#F5A078', linewidth=2)
	plt.plot(x, y[3], color='#004000', linewidth=2)
	plt.xlim(xl)
	plt.xticks(fontsize=20)
	plt.yticks(fontsize=20)
	plt.xlabel("Trade days", fontsize=25)
	plt.ylabel("Bollinger Feature", fontsize=25)
	plt.show()

def bollinger(symbol,delta,interval):

	# input GOOGL info
	matrix = acquire(symbol,interval)
	period  = len(matrix)

	# evaluate statistical parameters over lookback period
# --------------------------------------------------------------------------------------------
#
#   need extra month to accommodate stockchart
#
# --------------------------------------------------------------------------------------------
	print("\n\t   Date\t\t       Index\t\tPrice\t\tMean\t\tStDev\t\tFeature\n")
	std  = [0.0 for r in range(period)]
	mean = [0.0 for s in range(period)]
	rat  = [0.0 for t in range(period)]
	for i in range(delta-1,period):
		sm  = 0.0
		sd2 = 0.0
		for j in range(i-delta+1,i+1):
			sm = sm + float(matrix[j][6])
		mean[i] = sm/float(delta)
		for j in range(i-delta+1,i+1):
			d = float(matrix[j][6]) - mean[i]
			sd2 = sd2 + d**2.0
		std[i] = math.sqrt(sd2/float(delta))
		rat[i] = (float(matrix[i][6]) - mean[i])/std[i]
		print("\t%s\t\t%i\t\t%s\t\t%.4g\t\t%.4g\t\t%.4g" %(matrix[i][0],i,matrix[i][6],mean[i],std[i],rat[i]))

	# display results
	print("\n  # 40-period lookback cycles =\t%i\n" %(period-delta))
	plot(symbol,matrix,mean,std,rat,delta,period)
	return rat

def main():

	delta    = 40
	symbol   = "GOOGL"
	interval = ["2007-12-04","2009-12-31"]

	bf = bollinger(symbol,delta,interval)

main()
