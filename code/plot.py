import math
import matplotlib as mpl
import matplotlib.pyplot as plt

class reflect:

    def __new__(self):

        matrix = self.extract()
        self.plot(matrix)

    def extract():

        data   = open("reflect.Si",'r')
        stream = data.read()
        data.close()

        field  = 2
        entry  = ""
        val    = []
        matrix = []

        for ch in stream:
            entry = entry + ch
            if ch=='\s' or ch=='\t' or ch=='\n':
                if len(entry)>1:
                    val.append(entry[:-1])
                entry = ""
            if len(val)>=field:
                matrix.append(val)
                val = []

        return matrix[1:]

    def plot(matrix):

        mpl.rc('text', color='#C8A078')
        mpl.rc('figure', facecolor='black', edgecolor='black')
        mpl.rc('axes', edgecolor='#C6BDBA', labelcolor='#C8A078', facecolor='black', linewidth=2)
        mpl.rc('xtick', color='#C8A078')
        mpl.rc('ytick', color='#C8A078')
        plt.tick_params(bottom=False, top=False, left=False, right=False)

        plt.figure(1)
        T  = []
        R  = []
        Rc = []
        Rl = []
        Rh = []
        col   = ['#C8A078','#640064','#004040']
        p     = [0.000411231, -1.09148e-07, 4.67455e-09]
        sigma =  4.96852e-05
        print("\n\tT\tR\n")
        for i in matrix:
            t  = float(i[0])
            r  = float(i[1])
            rc = p[0] + p[1]*t + p[2]*t**2
            T.append(t)
            R.append(r)
            Rc.append(rc)
            Rl.append(rc - 2.*sigma)
            Rh.append(rc + 2.*sigma)
            print("\t%s\t%s" %(i[0], i[1]))
        print("\nmatrix size = %i" %len(matrix))
        line = plt.plot(T, Rc, color=col[0], linewidth=2)
        plt.setp(line, linestyle='dotted')
        plt.plot(T, Rl, color=col[1], linewidth=2)
        plt.plot(T, Rh, color=col[1], linewidth=2)
        plt.plot(T, R,  color=col[2], linewidth=3)
        plt.title('Fresnel Curve', fontsize=25)
        plt.xlabel('Temperature, C', fontsize=25)
        plt.ylabel('Reflectance', fontsize=25)
        plt.xticks(fontsize=20)
        plt.yticks(fontsize=20)
        plt.show()

def main():

    r = reflect()

main()
