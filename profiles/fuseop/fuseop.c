#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <limits.h>

#define INTOM 0.0254
#define BOXHIN 4.0
#define BOXLMULT 2.5

int QUIET = 0;

double **topcoord = NULL;
double **bottomcoord = NULL;
int topcoords = 0;
int bottomcoords = 0;
int *coords = &topcoords;

char *name = NULL;
double chord = 1;
double minx = 0;
double maxx = 1;
double inc = .00001;


int ldfile(const char *fn);
void optimise(void);
double top(double x);
double bottom(double x);
double interp(double upper, double lower, double upperx, double lowerx, double x);
void minfit(double *fitret);


int main(int argc, char **argv)
{
	double fitresults[2] = {0, 0};
	
	if(argc < 2)
	{
		puts("No input file specified");
		return -1;
	}
	
	if(argc >= 3 && argv[2] != NULL && !strncmp(argv[2], "-q", 2))
	{
		QUIET = 1;
	}

	if(ldfile(argv[1]) != 0)
	{
		return -1;
	}
	
	minfit(fitresults);
	
	if(fitresults[0] <= 0 || isnan(fitresults[0]))
	{
		if(!QUIET)
		{
			puts("Error in fitting box");
		}
		return -1;
	}
	
	if(QUIET)
	{
		printf("%f\n", (BOXHIN/fitresults[0]) * chord * INTOM);
	}
	else
	{
		printf("For a a 4\" x 10\" box, a chord of %fm is needed.\n", (BOXHIN/fitresults[0]) * chord * INTOM);
		printf("Box starts at %fm\n", (BOXHIN/fitresults[0]) * chord * INTOM * fitresults[1]);
	}

	free(topcoord[0]);
	free(topcoord[1]);
	free(bottomcoord[0]);
	free(bottomcoord[1]);
	free(topcoord);
	free(bottomcoord);

	return 0;
}

int ldfile(const char *fn)
{
	FILE *file;
	size_t len = 0;
	int ret;
	struct stat fstat;
	int asize;	
	double coordbuf[2][2];
	double **aptr;

	if(stat(fn, &fstat) < 0)
	{
		return -1;
	}
	
	topcoord = malloc(2);
	bottomcoord = malloc(2);

	if(topcoord == NULL || bottomcoord == NULL)
	{
		if(!QUIET)
		{
			perror("Unable to allocate memory");
		}
		return -1;
	}

	asize = fstat.st_size / 2;

	topcoord[0] = malloc(asize);
	topcoord[1] = malloc(asize);
	bottomcoord[0] = malloc(asize);
	bottomcoord[1] = malloc(asize);

	if(topcoord[0] == NULL || topcoord[1] == NULL || bottomcoord[0] == NULL || bottomcoord[1] == NULL)
	{
		if(!QUIET)
		{
			perror("Unable to allocate memory");
		}
		return -1;
	}

	aptr = topcoord;
	
	if(!QUIET)
	{
		printf("Opening aerofoil file %s\n", fn);
	}
	file = fopen(fn, "r");
	if(file == NULL)
	{
		if(!QUIET)
		{
			perror("Could not open file");
		}
		return -1;
	}
	getline(&name, &len, file);
	if(!QUIET)
	{
		printf("Reading data for aerofoil %s\n", name);
	}
	
	while(!feof(file))
	{
		ret = fscanf(file, "%lg %lg", &coordbuf[0][0], &coordbuf[1][0]);
		if(ret < 2)
		{
			break;
		}
		if(coordbuf[0][0] < minx)
		{
			minx = coordbuf[0][0];
		}
		else if(coordbuf[0][0] > maxx)
		{
			maxx = coordbuf[0][0];
		}
		if(*coords > 0 && aptr != bottomcoord)
		{
			if(coordbuf[0][0] - aptr[0][(*coords)-1] > 0 && aptr != bottomcoord)
			{
				aptr = bottomcoord;
				coords = &bottomcoords;
			}
		}
			
		aptr[0][*coords] = coordbuf[0][0];
		aptr[1][*coords] = coordbuf[1][0];

		(*coords)++;

	}
	fclose(file);
	chord = maxx - minx;
	return 0;
}

double top(double x)
{
	int i, lastx = 0, currx = 0;

	if(x < minx || x > maxx)
	{
		return nan("");
	}	

	for(i = 0; i < topcoords; i++)
	{
		lastx = currx;
		if((!(topcoord[0][i] < x)) && (!(topcoord[0][i] > x)))
		{
			return topcoord[1][i];
		}
		else if(topcoord[0][i] < x)
		{
			currx = -1;	
		}
		else if(topcoord[0][i] > x)
		{
			currx = 1;
		}
		if(lastx == 0)
		{
			continue;
		}
		else if(lastx != currx)
		{
			return interp(topcoord[1][i], topcoord[1][i-1], topcoord[0][i], topcoord[0][i-1], x);
		}
	}
	return nan("");
}

double bottom(double x)
{
	int i, lastx = 0, currx = 0;

	if(x < minx || x > maxx)
	{
		return nan("");
	}

	for(i = 0; i < bottomcoords; i++)
	{
		lastx = currx;
		if((!(bottomcoord[0][i] < x)) && (!(bottomcoord[0][i] > x)))
		{
			return bottomcoord[1][i];
		}
		else if(bottomcoord[0][i] < x)
		{
			currx = -1;
		}
		else if(bottomcoord[0][i] > x)
		{
			currx = 1;
		}
		if(lastx == 0)
		{
			continue;
		}
		else if(lastx != currx)
		{
			return interp(bottomcoord[1][i], bottomcoord[1][i-1], bottomcoord[0][i], bottomcoord[0][i-1], x);
		}
	}
	return nan("");
}

double interp(double upper, double lower, double upperx, double lowerx, double x)
{
	return lower + ((upper - lower) * ((x - lowerx) / (upperx - lowerx)));
}

void minfit(double *fitret)
{
	double i;
	double x = 0;
	double vdist = 0;
	double topy,bottomy;
	
	for(i = minx; i < maxx; i += inc)
	{
		topy = top(i);
		bottomy = bottom(i);
		vdist = topy - bottomy;
		if(isnan(topy) || isnan(bottomy) || vdist < 0)
		{
			continue;
		}
		x = i + (vdist * BOXLMULT);
		if(top(x) < topy || bottom(x) > bottomy)
		{
			continue;
		}
		if(vdist > fitret[0])
		{
			fitret[1] = i;
			fitret[0] = vdist;
		}
	}
}
