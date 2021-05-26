# List of defined commands
.PHONY: build clean kernel-clean run

# Path to image
IMAGE="lezione.hdd"

# Rule for xbstrap init
build/bootstrap.link:
	mkdir -p build
	cd build && xbstrap init .

# Generic image build rule
build: build/bootstrap.link
# Install echfs utils
	cd build && xbstrap install-tool echfs
# Reinstall system files
	cd build && xbstrap install system-files --rebuild
# Reinstall release kernel
	cd build && xbstrap install release-kernel --rebuild
# Reinstall debug kernel
	cd build && xbstrap install debug-kernel --rebuild
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
# Runs OS in qemu with kvm enabled
run: build
# Run QEMU
# -hda $(IMAGE) - Attach harddrive with our release image
# -cpu host --accel kvm --accel hax --accel tcg - Use hardware virtualization if available
# If no hardware acceleration is present, fallback to tcg with --accel tcg
# -debugcon stdio - Add debug connection, so that we can print logs to e9 port from the kernel
# and see them in the terminal
	qemu-system-x86_64 -hda $(IMAGE) --accel kvm --accel hax --accel tcg -debugcon stdio
