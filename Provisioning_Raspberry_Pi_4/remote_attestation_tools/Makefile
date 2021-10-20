CC = gcc
CFLAG = -Wno-deprecated-declarations -lcurl -lconfig -ljson-c -lcrypto

all: attune.c atelic.c attest.c
	$(CC) $(CFLAG) -o ./bin/CSR CSR.c
	$(CC) $(CFLAG) -o ./bin/KCV KCV.c
	$(CC) $(CFLAG) -o ./bin/attune attune.c
	$(CC) $(CFLAG) -o ./bin/atelic atelic.c
	$(CC) $(CFLAG) -o ./bin/attest attest.c
	$(CC) $(CFLAG) -o ./bin/decrypt decrypt.c

clean:
	rm ./bin/attune ./bin/atelic ./bin/attest ./bin/KCV ./bin/decrypt
