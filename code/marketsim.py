import sys
import os
#import wget
import shutil

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

def gather(orders):

	# read order file
	data = open(orders,'r')
	stream = data.read()
	data.close()

	# input order data
	field = 6
	entry = ""
	val   = []
	fmt   = []
	odata = []

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
			fmt.append(val[4])
			fmt.append(val[5])
			odata.append(fmt)
			val = []
			fmt = []

	odata.sort()
	return odata

def execute(orders,initial,interval,values):

	# retrieve market data
	symbol = []
	matrix = []
	odata  = gather(orders)
	print()
	for i in range(0,len(odata)):
		print("%s\t%s\t%s\t%s" %(odata[i][0],odata[i][1],odata[i][2],odata[i][3]))
		if odata[i][1] in symbol:
			continue
		symbol.append(odata[i][1])
		matrix.append(acquire(odata[i][1],interval))

	# process daily value
	stream = ""
	cash   = initial
	shr    = [0.0 for i in range(len(symbol))]
	for i in range(0,len(matrix[0])):
		date = matrix[0][i][0]
		for j in range(0,len(odata)):
			if date==odata[j][0]:
				for k,item in enumerate(symbol):
					if odata[j][1]==symbol[k]:
						delta=float(odata[j][3])
						equity = delta*float(matrix[k][i][6])
						if odata[j][2]=="Buy":
							cash   = cash - equity
							shr[k] = shr[k] + delta
						if odata[j][2]=="Sell":
							cash   = cash + equity
							shr[k] = shr[k] - delta
		val = cash
		for j,item in enumerate(symbol):
			val = val + shr[j]*float(matrix[j][i][6])
		stream  = stream + "%s,%s,%s,%.8g\n" %(date[0:4],date[5:7],date[8:10],val)

	# write data file
	output = open("values.csv",'w')
	output.write(stream)
	output.close()
	print("\ninitial = %.8g\norders  = %s\nvalues  = %s\n" %(initial,orders,values))

def main():

	initial = float(sys.argv[1])
	orders = sys.argv[2]
	values = sys.argv[3]
	interval = ["2008-01-03","2009-12-28"]

	execute(orders,initial,interval,values)

main()
