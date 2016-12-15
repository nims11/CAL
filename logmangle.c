#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>

#define delta .004  //best for trec05p-1

double w[100],sc[100],score, prob;

char njudge[100], judge[100], file[100], nfile[100], cl[100][100];
unsigned b,h;
int i,j,k,n;
int isspam;
FILE *f[100];

int main(int argc, char **argv){
   for (i=1;i<argc;i++) {
      f[i] = fopen(argv[i],"r");
      if (!f[i]) {
         perror(argv[i]);
         exit(1);
      }
      w[i] = 1.0/(argc-1);
   }
   int x = 0;
   while (4 == fscanf(f[1],"%s judge=%s class=%s score=%lf%*[^\n]",file,judge,cl[1],&sc[1])){
      isspam = !strcasecmp(judge,"spam");
      for (i=2;i<argc;i++) {
         if (4 !=  fscanf(f[i],"%s judge=%s class=%s score=%lf%*[^\n]",nfile,njudge,cl[i],&sc[i])){
            printf("short read %s\n",argv[i]);
         } 
         if (strcmp(judge,njudge)) printf("whoops %s %s %s %s\n",file,judge,nfile,njudge);
         assert(!strcasecmp(judge,njudge));
      }

      score = 0;
      for (i=1;i<argc;i++) score += w[i] * sc[i];
      prob = 1/(1+exp(-score));
      printf("%s judge=%s class=%s score=%0.5lf %0.5lf\n",file,judge,score>0?"spam":"ham",score,prob);
      if (strcmp(judge,"Spam") && strcmp(judge,"Ham")){
          for (i=1;i<argc;i++){
              w[i] += (isspam-prob) * delta * sc[i];
          }
      }else if(!x){
          x = 1;
          /* fprintf(stderr, "%0.5lf %0.5lf\n", w[1], w[2]); */
      }
      //for (i=1;i<argc;i++) printf("%0.5lf ",w[i]);  printf("\n");
   }
   return 0;
}
