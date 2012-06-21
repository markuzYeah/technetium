test:
	@./node_modules/.bin/mocha --compilers coffee:coffee-script -R spec -t 10000 -u bdd

.PHONY: test

