.PHONY : typechain compile test compile-clean console run deploy prettier

typechain:
	./node_modules/.bin/typechain --target ethers-v5 --outDir typechain './artifacts/*.json'

compile:
	npx buidler compile
	make typechain

compile-clean:
	npx buidler clean
	make compile

test:
	npm run-script test test/LockedLendingPoolNftTest.ts

run-node:
	@npx buidler node

deploy:
	npx buidler run deployTest.ts

prettier:
	npm run prettier