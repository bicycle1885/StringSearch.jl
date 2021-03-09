libstrsearch.so: libstrsearch.cpp
	#gcc -O0 -g -shared -fpic -o $@ $<
	gcc -O3 -march=native -shared -fpic -o $@ $<

clean:
	rm -rf libstrsearch.so