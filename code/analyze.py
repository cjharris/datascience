import sys
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

def finance(matrix):

	tsh = 252.0
	r   = [0.0 for m in range(4)]
	dr  = [0.0 for n in range(len(matrix))]

	# total return
	r[0] = float(matrix[len(matrix)-1][1])/float(matrix[0][1]) - 1.0

	# daily return
# --------------------------------------------------------------------------------------------
#
#   leave first element 'dr[0]' = 0
#
# --------------------------------------------------------------------------------------------
	for i in range(1,len(matrix)):
		dr[i] = float(matrix[i][1])/float(matrix[i-1][1]) - 1.0

	# mean daily return
	sdr = 0.0
	for i, item in enumerate(matrix):
		sdr = sdr + dr[i]
	r[1] = sdr/float(len(matrix))

	# standard deviation
	sd2 = 0.0
	for i, item in enumerate(matrix):
		d = r[1] - dr[i]
		sd2 = sd2 + d**2.0
	r[2] = math.sqrt(sd2/float(len(matrix)))

	# sharpe ratio
	r[3] = math.sqrt(tsh)*r[1]/r[2]
	return r,dr

def linearregression(matrix):

	s0  = 0.
	sx  = 0.
	sx2 = 0.
	sy  = 0.
	sxy = 0.
	X   = [0.0 for l in range(len(matrix))]
	Y   = [0.0 for m in range(len(matrix))]
	p   = [0.0 for n in range(3)]

	for i, item in enumerate(matrix):
		X[i] = float(i)
		Y[i] = float(matrix[i][1])
		s0   = s0 + 1.
		sx   = sx + X[i]
		sx2  = sx2 + X[i]*X[i]
		sy   = sy + Y[i]
		sxy  = sxy + X[i]*Y[i]

	meanx = sx/s0
	meany = sy/s0
	p[0]  = (s0*sxy - sx*sy)/(s0*sx2 - sx*sx)
	p[1]  = meany - p[0]*meanx
	ssy   = 0.
	ssr   = 0.

	for i, item in enumerate(matrix):
		ssy = ssy + (Y[i] - meany)*(Y[i] - meany)
		ssr = ssr + (Y[i] - p[1] - p[0]*X[i])*(Y[i] - p[1] - p[0]*X[i])
	p[2] = math.sqrt(1.0 - ssr/ssy)
	return p

def plot(label,symbol,matrix,array,p):

	X  = []
	Y  = []
	xl = [-10,len(array)+10]

	mpl.rc('text', color='#C8A078')
	mpl.rc('figure', facecolor='black', edgecolor='black')
	mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
	mpl.rc('xtick', color='#C8A078')
	mpl.rc('ytick', color='#C8A078')
	plt.tick_params(bottom=False, top=False, left=False, right=False)

	plt.figure(1)
	for i in range(0,len(array)):
		X.append(float(i))
		Y.append(p[0]*X[i] + p[1])
	plt.plot(X, Y, color='#F5A078', linewidth=2)
	Y  = []
	for i in range(0,len(array)):
		Y.append(float(array[i][1]))
	plt.plot(X, Y, color='#004040', linewidth=2, label="Port")
	color = ['#640000','#004000','#004040','#640064']
	Y  = []
	for i in range(0,len(array)):
		Y.append(float(matrix[i][1])/float(matrix[0][1])*float(array[0][1]))
	plt.plot(X, Y, color='#640064', linewidth=2, label=symbol)

	plt.xlim(xl)
	plt.legend(loc=(0.8,0.56), frameon=False, fontsize=20)
	fmt = "equity = %.4gt + %.4g\n    corr = %.4g\n" %(p[0],p[1],p[2])
	plt.annotate(fmt, xy=(25,900000), fontsize=20)
	plt.title("%s Performance: %s to %s" %(label,array[0][0],array[len(array)-1][0]), fontsize=25)
	plt.xticks(fontsize=20)
	plt.yticks(fontsize=20)
	plt.xlabel("Trade day", fontsize=25)
	plt.ylabel("Value, dollar", fontsize=25)
	plt.show()

def valdata(values):

	# read value file
	data = open(values,'r')
	stream = data.read()
	data.close()

	# input value data
	field = 4
	entry = ""
	val   = []
	fmt   = []
	vdata = []

	for ch in stream:
		entry = entry + ch
		if ch==',' or ch=='\n':
			if len(entry)>1:
				val.append(entry[:-1])
			entry = ""
		if len(val)>=field:
			for i in range(1,3):
				if len(val[i]) < 2:
					val[i] = '0' + val[i]
			fmt.append("%s-%s-%s" %(val[0],val[1],val[2]))
			fmt.append(val[3])
			vdata.append(fmt)
			val = []
			fmt = []
	return vdata

def refdata(vdata,symbol):

	# retrieve market data
	interval = [vdata[0][0],vdata[len(vdata)-1][0]]
	matrix = acquire(symbol,interval)
	period = len(matrix)
	print()
	val   = []
	rdata = []
	for i in range(0,period):
		val.append(matrix[i][0])
		val.append(matrix[i][6])
		rdata.append(val)
		val = []
		if i==0 or i==period-1:
			print("%s\t%s" %(vdata[i][0],vdata[i][1]))
	return rdata

def analyze(values,symbol):

	vdata = valdata(values)
	rdata = refdata(vdata,symbol)

	# output results
	r,dr = finance(vdata)
	p    = linearregression(vdata)
	f    = ("\nPortfolio:\n\ntotal return       = %.4g\nmean daily return  = %.4g\nstandard deviation = %.4g\nSharpe ratio       = %.4g"
	%(r[0],r[1],r[2],r[3]))
	print(f)

	r,dr = finance(rdata)
	f    = ("\n$SPX:\n\ntotal return       = %.4g\nmean daily return  = %.4g\nstandard deviation = %.4g\nSharpe ratio       = %.4g\n"
	%(r[0],r[1],r[2],r[3]))
	print(f)
	plot("Portfolio",symbol,rdata,vdata,p)

def main():

	values = sys.argv[1]
	symbol = sys.argv[2]

	analyze(values,symbol)

main()
