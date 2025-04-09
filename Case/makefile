Case: Case.o
	ld -o Case Case.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64 

Case.o: Case.s
	as -arch arm64 -o Case.o Case.s