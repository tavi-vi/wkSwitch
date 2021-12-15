
exe = switch

${exe}: main.c
	musl-gcc -static -DJSMN_PARENT_LINKS -DJSMN_STRICT -O3 -o ${exe} main.c

.PHONY: install
install:
	mkdir ${out}/bin
	cp ${exe} ${out}/bin/
