
exe = zig-out/bin/wkSwitch

.PHONY: install ${exe}
${exe}:
	zig build

install:
	mkdir ${out}/bin
	cp ${exe} ${out}/bin/wkswitch
