.PHONY: bin clean dict dictclean all allclean
export step = 0
export TKD53HOME = $(shell pwd)

bin:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean
	rm src/main

dict:
	cd dictionary/WordKKCI-2 && LC_ALL='C' bin/MakeDir.csh $(step)
	cd dictionary/KKConv/WordKKCI-2 && LC_ALL='C' bin/MakeDir.csh $(step)

dictclean:
	cd dictionary/WordKKCI-2 && rm -Rf Step$(step)
	cd dictionary/KKConv/WordKKCI-2 && rm -Rf Step$(step)

all: dict bin

allclean: clean dictclean
