libstrsearch.so: libstrsearch.cpp
	#gcc -O0 -g -shared -fpic -o $@ $<
	gcc -O3 -mavx2 -shared -fpic -o $@ $<

clean:
	rm -rf libstrsearch.so