# List of defined commands
.PHONY: build-release build-debug clean kernel-clean run

# Path to compiler that will be used for kernel
CC = build/xbstrap-dir/tools/kernel-gcc/bin/x86_64-elf-gcc

# Release image build rule
# First rule line sets path to kerenl binary, second rule line sets output path for final image,
# third sets build mode for the kernel
# Those variables are passed as arguments to main build rule
build-release: KERNEL = lezione-kernel-release.elf 
build-release: IMAGE = lezione-release.hdd
build-release: MODE = release
build-release: build

# Debug image build rule
build-debug: KERNEL = lezione-kernel-debug.elf
build-debug: IMAGE = lezione-debug.hdd
build-debug: MODE = debug
build-debug: build

# Rule for building echfs
echfs:
	make -C deps/echfs

# Rule for xbstrap init
build/xbstrap-dir/bootstrap.link:
	mkdir -p build/xbstrap-dir
	cd build/xbstrap-dir && xbstrap init ..

# Rule for compiling toolchain
$(CC): build/xbstrap-dir/bootstrap.link
	cd build/xbstrap-dir && xbstrap install-tool kernel-gcc

# Generic image build rule
build: echfs $(CC)
# Make release kernel
	make -C src/kernel $(MODE)
# Delete existing release
	rm -rf $(IMAGE)
# Make a new image with 64 Megabytes of disk space.
# seek is used to allocate space without filling it
# with zeroes
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(IMAGE)
# Create GPT partition table on disk
	parted -s $(IMAGE) mklabel gpt
# Create one partition that will be used for the kernel
	parted -s $(IMAGE) mkpart primary 2048s 100%
# Format this partition to echfs filesystem
	./deps/echfs/echfs-utils -g -p0 $(IMAGE) quick-format 512
# Copy kernel elf file to the new filesystem
	./deps/echfs/echfs-utils -g -p0 $(IMAGE) import src/kernel/$(KERNEL) lezione-kernel.elf
# Copy limine configuration file to the new filesystem
	./deps/echfs/echfs-utils -g -p0 $(IMAGE) import limine.cfg limine.cfg
# Copy limine stage 3 to the new filesystem
	./deps/echfs/echfs-utils -g -p0 $(IMAGE) import deps/limine/limine.sys limine.sys
# Install limine stages 1 and 2 to the disk image
	./deps/limine/limine-install-linux-x86_64 $(IMAGE)

# Clean rule
# Deletes kernel object files, kernel binaries, and images
clean:
	make -C kernel clean
	rm -rf lezione-debug.hdd lezione-release.hdd

# Binary clean rule
# Clears only kenrel binaries
kernel-clean:
	make -C kernel clean

# Run release image rule
# Runs OS in qemu with kvm enabled
run: build-release
# Run QEMU
# -hda lezione-release.hdd - Attach harddrive with our release image
# -cpu host --accel kvm --accel hax --accel tcg - Use hardware virtualization if available
# If no hardware acceleration is present, fallback to tcg with --accel tcg
# -debugcon stdio - Add debug connection, so that we can print logs to e9 port from the kernel
# and see them in the terminal
	qemu-system-x86_64 -hda lezione-release.hdd --accel kvm --accel hax --accel tcg -debugcon stdio
