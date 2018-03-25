import math
import pickle
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

class stat:

    def max(self,X):

        m = X[0]
        for e in X:
            if e > m:
                m = e
        return m

    def mean(self,X):

        s = 0.
        for e in X:
            s = s + e
        return s/len(X)

    def var(self,X,mx):

        s = 0.
        for e in X:
            s = s + (e-mx)**2
        return s/(len(X)-1)

    def cor(self,X,Y,mx,my,sx,sy):

        s = 0.
        for i,e in enumerate(X):
            s = s + (X[i]-mx)*(Y[i]-my)
        return s/sx/sy/(len(X)-1)

    def regression(self,X,Y):

        # mean
        mx = self.mean(X)
        my = self.mean(Y)

        # standard deviation
        sx = math.sqrt(self.var(X,mx))
        sy = math.sqrt(self.var(Y,my))

        # correlation
        rxy = self.cor(X,Y,mx,my,sx,sy)

        # slope, intercept, coefficient
        p    = [[] for n in range(3)]
        p[0] = rxy*sy/sx
        p[1] = my - p[0]*mx
        p[2] = rxy
        return p

st = stat()

class tune:

    def __new__(self):

        key    = [['stim','neuron1','neuron2','neuron3','neuron4'],['r1','r2','r3','r4','c1','c2','c3','c4']]
        idim   = len(key[0])
        tarray = self.calc(key[0],idim)
        parray = self.pop(key[1])
        rmax   = self.peak(tarray,idim)
        self.angle(parray,rmax)
        self.plot(tarray,idim)

    def calc(key,idim):

        data   = open("../data/tuning.pickle",'rb')
        stream = pickle.load(data)
        data.close()

        array    = [[] for i in range(idim+4)]
        array[0] = stream[key[0]]
        jdim     = len(array[0])
        set      = []

        for i in range(1,idim):
            set = stream[key[i]]
            mx = []
            vx = []
            for j in range(jdim):
                row = []
                for k in range(jdim):
                    row.append(set.item((k,j)))
                mx.append(st.mean(row))
                vx.append(st.var(row,mx[-1]))
            array[i]   = mx
            array[i+4] = vx
        return array

    def pop(key):

        data   = open("../data/pop_coding.pickle",'rb')
        stream = pickle.load(data)
        data.close()

        dim   = len(key)
        array = [[] for i in range(dim)]
        for i in range(dim):
            array[i] = stream[key[i]]
        return array

    def peak(array,idim):

        fmt  = ""
        rmax = []
        for i in range(1,idim):
            rmax.append(st.max(array[i]))
            fmt = fmt + "%7.3f," %rmax[-1]
        print("\n\tRmax  = [%s ]" %fmt[:-1])
        return rmax

    def angle(array,rmax):

        s = [0. for i in range(2)]
        for i in range(2):
            for e in array[i]:
                s[0] = s[0] + e/rmax[i]*array[i+4][0]
                s[1] = s[1] + e/rmax[i]*array[i+4][1]
        angle = math.degrees(math.atan(s[1]/s[0]))
        print("\tVpop  = [%7.3f,%7.3f ]\n\tangle = %10.1f deg\n" %(s[0],s[1],angle))

    def plot(tarray,idim):

        mpl.rc('text', color='#C8A078')
        mpl.rc('figure', facecolor='black', edgecolor='black')
        mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
        mpl.rc('xtick', color='#C8A078')
        mpl.rc('ytick', color='#C8A078')
        plt.tick_params(bottom=False, top=False, left=False, right=False)

        plt.figure(1)
        col = ['#640000','#004000','#004040','#640064']
        for i in range(1,idim):
        	plt.plot(tarray[0], tarray[i], color=col[i-1], label="neuron %i" %i, linewidth=3)
        plt.legend(loc=(0.85,0.8), frameon=False, fontsize=20)
        plt.title('Tuning Curve', fontsize=25)
        plt.xlabel('Angle [deg]', fontsize=25)
        plt.ylabel('Neuron firing rate [Hz]', fontsize=25)
        plt.xticks(fontsize=20)
        plt.yticks(fontsize=20)

        plt.figure(2)
        plt.xlim(0,35)
        plt.ylim(0,5)
        mark = ['o','s','^','d']
        for i in range(1,idim):
            plt.plot(tarray[i], tarray[i+4], color=col[i-1], marker=mark[i-1], markersize=20,
                     markeredgewidth=3, fillstyle='none', label='neuron %i' %i, linewidth=0)
        for i in [1,3]:
            p = st.regression(tarray[i],tarray[i+4])
            Y = []
            for e in tarray[i]:
                Y.append(p[0]*e + p[1])
            plt.plot(tarray[i], Y, color='#F5A078', linewidth=3)
        plt.legend(loc=(0.85,0.05), frameon=False, numpoints=1, fontsize=20)
        plt.title('Poisson Check', fontsize=25)
        plt.xlabel('Neuron firing rate [Hz]', fontsize=25)
        plt.ylabel('Variance [Hz^2]', fontsize=25)
        plt.xticks(fontsize=20)
        plt.yticks(fontsize=20)
        plt.show()

def main():

    t = tune()

main()
