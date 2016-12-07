all:
	gcc -Wall -O2 -o kisssdb/kisssdb kisssdb/kisssdb.c

clean:
	rm -f kisssdb/kisssdb
