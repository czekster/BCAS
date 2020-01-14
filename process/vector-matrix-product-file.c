/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 * Following code does a Vector-Matrix Product (VMP) for a Discrete Time Markov Chain (DTMC).
 * Input is a DTMC (stochastic matrix) described in a FILE (look at dtmc.txt).
 * Output is a uniformised probability vector.
 * Author: Ricardo M. Czekster (rczekster@gmail.com)
 * Date: 25/11/2019
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>     // memcpy
#include <math.h>       // pow, sqrt

#define LIMIT   1024    // line size limit
#define MAXRUNS 1000000 // number of runs
#define RESIDUE 1e-10   // residual difference between two iterations

/** Checks for convergence, i.e., all positions from two vectors must be greater than the RESIDUE constant. */
int converge(float *r1, float *r2, int o) {
   int i;
   for (i = 0; i < o; i++)
      if (sqrt(pow(r1[i] - r2[i], 2)) > RESIDUE)
         return 0;
   return 1;
}

/** Performs a vector-matrix product. */
void multiply(float *v, float **m, int o) {
   int i,j;
   float aux[o];
   for (i = 0; i < o; i++) {
      aux[i] = 0;
      for (j = 0; j < o; j++)
         aux[i] += m[j][i] * v[j];
   }
   memcpy(v, aux, sizeof(float) * o);
}

// traverse file (first line) and return a 'tentative' order (it will have to pass other tests later)
int find_order(char* file) {
   int i=0, j=0;
   int orderj=0;
   FILE *fp;
   char line[LIMIT];
   char *pch;
   fp = fopen(file, "r");
   if (fp == NULL) {
      printf("Error while opening file.\n");
      exit(1);
   }
   while (fgets( line, LIMIT, fp) != NULL ) {
      line[strcspn(line, "\n")] = 0;  // remove \n from line
      if (line[0] == '#')             // bypass comments
          continue;
      pch = strtok(line," ");
      do {
         j++;
         pch = strtok(NULL, " ");
      } while (pch != NULL);
      orderj = j;
      break;
   }
   fclose(fp);
   return orderj;
}

void openDTMC(char* file, float **m) {
   int i=0, j=0;
   int orderj=0;
   FILE *fp;
   float rowsum;
   char line[LIMIT];
   char *pch;
   fp = fopen(file, "r");
   if (fp == NULL) {
      printf("Error while opening file.\n");
      exit(1);
   }
   while (fgets( line, LIMIT, fp) != NULL ) {
      line[strcspn(line, "\n")] = 0;  // remove \n from line
      if (line[0] == '#')             // bypass comments
          continue;
      pch = strtok(line," ");
      rowsum = 0.0;
      do {
         m[i][j] = atof(pch);
         rowsum += m[i][j];
         j++;
         pch = strtok(NULL, " ");
      } while (pch != NULL);
      i++;
      orderj = j;
      j = 0;
      if (rowsum > 1.0 && rowsum < 0.9999) {
          printf("error in line: not summing to one (sum=%4.8f).\n", rowsum);
          exit(1);
       }
   }
   if (i != orderj) {
      printf("error in matrix: incorrect order.\n");
      exit(1);
   }
   fclose(fp);
}

int main(int argc, char *argv[]) {
   int i,j;
   int runs = 0;
   float **D;       // it will be filled by a file (e.g. "dtmc.txt" -- see above)
   float *pvec;
   float *old;
   if (argc < 2) {
      printf("Invalid number of parameters.\nUsage: vmp.exe FILE\n");
      exit(0);
   }
   char filename[128];
   strcpy(filename, argv[1]);
   int order = find_order(filename);

   D = (float**) malloc(sizeof(float*) * order);
   for (i = 0; i < order; i++)
        D[i] = (float*) malloc(sizeof(float) * order);
   pvec = (float*) malloc(sizeof(float) * order);
   old = (float*) malloc(sizeof(float) * order);

   openDTMC(filename, D);

   /** //prints the matrix
   for (i = 0; i < order; i++) {
      for (j = 0; j < order; j++) {
         printf("%f ", D[i][j]);
      }
      printf("\n");
   }
   /**/
   pvec[0] = 1.0;  // initialise first position
   for (i = 1; i < order; i++)
      pvec[i] = 0.0;
   do {
      memcpy(old, pvec, sizeof(float) * order); // copy to old array
      multiply(pvec, D, order);
      if (++runs > MAXRUNS)
         break;
   } while (!converge(old, pvec, order));
   //printf("Number of iterations: %d\n", runs-1);
   int outcome = (MAXRUNS==runs-1 ? 0 : 1);
   printf("%d;",outcome);
   for (i = 0; i < order-1; i++)
      printf("%f;", pvec[i]);
   printf("%f", pvec[i]);
   printf("\n");

   // dealloc matrix and vectors
   for (i = 0; i < order; i++)
      free(D[i]);
   free(D);
   free(pvec);
   free(old);
}
