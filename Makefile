# List of defined commands
# build rule is not to be used by the user, however it is included in this list to make makefile
# evaluate it
.PHONY: build-debug build-release clean kernel-clean run-release

# Rule for xbstrap init
build/bootstrap.link:
	mkdir -p build
	cd build && xbstrap init .

# Build image with release kernel
lezione-release.hdd: KERNEL_PKG = "release-kernel"
lezione-release.hdd: IMAGE = "lezione-release.hdd"
lezione-release.hdd: image

# Build image with debug kernel
lezione-debug.hdd: KERNEL_PKG = "debug-kernel"
lezione-debug.hdd: IMAGE = "lezione-debug.hdd"
lezione-debug.hdd: image

# Generic image build rule
image: build/bootstrap.link
# Install echfs utils
	cd build && xbstrap install-tool echfs
# Reinstall system files
	cd build && xbstrap install system-files --rebuild
# Reinstall kernel
	cd build && xbstrap install $(KERNEL_PKG) --rebuild
# Reinstall limine stage 3
	cd build && xbstrap install limine-stage3 --rebuild
# Delete existing image
	rm -rf $(IMAGE)
# Make a new image with 64 Megabytes of disk space. seek is used to allocate space without actually
# filling it with zeroes.
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(IMAGE)
# Create GPT partition table on disk
	parted -s $(IMAGE) mklabel gpt
# Create one partition that will be used for the kernel
	parted -s $(IMAGE) mkpart primary 2048s 100%
# Format this partition to echfs filesystem
	./build/build-tools/echfs/echfs-utils -g -p0 $(IMAGE) quick-format 512
# Delete mountpoint target.
	rm -rf build/sysroot-mount
	mkdir -p build/sysroot-mount
	./build/build-tools/echfs/echfs-fuse --gpt -p0 $(IMAGE) build/sysroot-mount
# Copy system root to echfs
	cp -r build/system-root/* build/sysroot-mount/
# Unmount echfs
	fusermount -z -u build/sysroot-mount
# Remove mountpoint
	rm -rf build/sysroot-mount/
# Install limine on the resulting image
	./build/build-tools/limine/limine-install $(IMAGE)

# Clean rule
# Deletes kernel object files, kernel binaries, and images
clean:
	make -C kernel clean
	rm -rf lezione-debug.hdd lezione-release.hdd

# Binary clean rule
# Clears only kenrel binaries and object files
kernel-clean:
	make -C kernel clean

# Run release image rule
# Runs OS in QEMU with kvm enabled
run-release: lezione-release.hdd
# Run QEMU
# -hda lezione-release.hdd - Attach hard drive with our image
# -cpu host --accel kvm --accel hax --accel tcg - Use hardware virtualization if available
# If no hardware acceleration is present, fallback to tcg with --accel tcg
# -debugcon stdio - Add debug connection, so that we can print logs to e9 port from the kernel
# and see them in the terminal
# -no-shutdown -no-reboot - Halt on fatal errrors
	qemu-system-x86_64 \
	-hda lezione-release.hdd \
	--accel kvm --accel hax --accel tcg \
	-debugcon stdio \
	-no-shutdown -no-reboot

# Run debug image rule
run-debug: lezione-debug.hdd
# Run QEMU
# -hda lezione-debug.hdd - Attach harddrive with our image
# -cpu host --accel kvm --accel hax --accel tcg - Use hardware virtualization if available
# If no hardware acceleration is present, fallback to tcg with --accel tcg
# -debugcon stdio - Add debug connection, so that we can print logs to e9 port from the kernel
# and see them in the terminal
# -S -s - attach and wait for the debugger
# -no-shutdown -no-reboot - Halt on fatal errrors
	qemu-system-x86_64 \
	-hda lezione-debug.hdd \
	--accel kvm --accel hax --accel tcg \
	-debugcon stdio \
	-S -s \
	-no-shutdown -no-reboot \

# Attach GDB to running session
gdb-attach:
	gdb -x gdb-startup
