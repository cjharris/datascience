import math
import pickle
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

class sta:

    def __new__(self):

        rho, stim = self.extract()
        period    = 2 # [ms]
        timestep  = int(300/period)
        time, sf  = self.calc(rho, stim, period, timestep)
        self.plot(time, sf)

    def extract():

        data   = open("../data/c1p8.pickle",'rb')
        stream = pickle.load(data)
        data.close()
        return stream['rho'], stream['stim']

    def calc(rho, stim, period, timestep):

        sf       = [0. for n in range(timestep+1)]
        step     = [[] for n in range(timestep+1)]
        time     = [[] for n in range(timestep+1)]
        location = []

        for i,e in enumerate(rho[timestep+1:]):
            if e:
                location.append(i+timestep)

        spike = len(location)
        f     = 1/spike
        print("\n\tspike = %i\n" %spike)

        for j in range(timestep+1):
            step[j] = -timestep + j
            time[j] =  period*step[j]

        for i in location:
            for j in range(timestep+1):
                sf[j] = sf[j] + f*stim[i+step[j]]
        return time, sf

    def plot(time, sf):

        mpl.rc('text', color='#C8A078')
        mpl.rc('figure', facecolor='black', edgecolor='black')
        mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
        mpl.rc('xtick', color='#C8A078')
        mpl.rc('ytick', color='#C8A078')
        plt.tick_params(bottom=False, top=False, left=False, right=False)

        plt.figure(1)
        plt.ylim(-2,32)
        plt.plot(time, sf, color='#004040', linewidth=3)
        plt.title('Spike-Triggered Average', fontsize=25)
        plt.xlabel('Time [ms]', fontsize=25)
        plt.ylabel('Stimulus', fontsize=25)
        plt.xticks(fontsize=20)
        plt.yticks(fontsize=20)
        plt.show()

def main():

    s = sta()

main()
