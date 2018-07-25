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

def plot(label,mean,std,delta):

	X  = []
	Y  = []
	xl = [-delta-1,delta+1]

	mpl.rc('text', color='#C8A078')
	mpl.rc('figure', facecolor='black', edgecolor='black')
	mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
	mpl.rc('xtick', color='#C8A078')
	mpl.rc('ytick', color='#C8A078')
	plt.tick_params(bottom=False, top=False, left=False, right=False)

	plt.figure(1)
	for i in range(0,2*delta+1):
		x = []
		y = []
		x.append(float(i-delta))
		x.append(x[0])
		y.append(mean[i] - std[i])
		y.append(mean[i] + std[i])
		if x[0] > 0.0:
			plt.plot(x, y, color='#F5A078', linewidth=1)
		X.append(x[0])
		Y.append(mean[i])
	plt.plot(X, Y, color='#004040', linewidth=2)
	plt.xlim(xl)
	plt.title("%s Mean Return Relative to S&P500 Index: 2008 to 2009" %label, fontsize=25)
	plt.xticks(fontsize=20)
	plt.yticks(fontsize=20)
	plt.xlabel("Trade days", fontsize=25)
	plt.ylabel("Cumulative Return", fontsize=25)

	plt.figure(2)
	plt.plot(X, Y, color='#004040', linewidth=2)
	plt.xlim(xl)
	plt.title("%s Mean Return Relative to S&P500 Index: 2008 to 2009" %label, fontsize=25)
	plt.xticks(fontsize=20)
	plt.yticks(fontsize=20)
	plt.xlabel("Trade days", fontsize=25)
	plt.ylabel("Cumulative Return", fontsize=25)
	plt.show()

def process(spfile):

	# read symbol file
	data   = open(spfile,'r')
	stream = data.read()
	data.close()

	# process symbol list
	entry  = ""
	symbol = []
	for ch in stream:
		entry = entry + ch
		if ch==',' or ch=='\n':
			if len(entry)>1:
				symbol.append(entry[:-1])
			entry = ""
	return symbol

def event(spfile,interval,ofile):

	hold  = 5
	delta = 20
	shr   = 100
	ref   = "SPY"
	act   = ["Sell","Buy"]

	# obtain reference data
	rmatrix = acquire(ref,interval)
	period  = len(rmatrix)
	print("\nperiod:\t%s to %s\n\t%i overall trade days\n\nomit:" %(interval[0],interval[1],period),end="")

	# check for event
	ev     = 0
	stream = ""
	array  = []
	sdt    = [0.0 for p in range(2*delta+1)]
	symbol = process(spfile)

	for sym in symbol:
		matrix = acquire(sym,interval)
		if len(matrix) < period:
			print("\t%s" %sym)
			continue

		for i in range(delta,period-delta):
			if float(matrix[i-1][6]) >= 5.0 and float(matrix[i][6]) < 5.0:
				date    = matrix[i][0]
				stream  = stream + "%s,%s,%s,%s,%s,%s,\n" %(date[0:4],date[5:7],date[8:10],sym,act[1],shr)
				date    = matrix[i+hold][0]
				stream  = stream + "%s,%s,%s,%s,%s,%s,\n" %(date[0:4],date[5:7],date[8:10],sym,act[0],shr)

				l = 0
				array.append([0.0 for q in range(2*delta+1)])
				for j in range(i-delta,i+delta+1):
					dt = float(matrix[j][6])/float(matrix[i][6])-float(rmatrix[j][6])/float(rmatrix[i][6])
					array[ev][l] = dt
					sdt[l] = sdt[l] + dt
					l = l + 1
				ev = ev + 1

	# evaluate event data
	std  = [0.0 for r in range(2*delta+1)]
	mean = [0.0 for s in range(2*delta+1)]
	for i in range(0,2*delta+1):
		sd2 = 0.0
		mean[i] = sdt[i]/float(ev)
		for j in range(0,ev):
			d = array[j][i] - mean[i]
			sd2 = sd2 + d**2.0
		std[i] = math.sqrt(sd2/float(ev))

	# write data file
	output = open(ofile,'w')
	output.write(stream)
	output.close()

	# display results
	print("\nEvent count = %i\n" %ev)
	plot("Event",mean,std,delta)

def main():

	ofile    = "orders.csv"
	spfile   = "sp5002012.txt"
	interval = ["2008-01-03","2009-12-28"]

	event(spfile,interval,ofile)

main()
