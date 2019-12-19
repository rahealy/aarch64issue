#
# Makefile

# Targets:
#
#  all - Builds debug version.
#  release - Builds optimized release version.
#  clean - Cleans the build directories
#
# Example:
#  $ make clean release
#

#######################################################################
# Variables
#######################################################################

CONTAINER_UTILS   = andrerichter/raspi3-utils

DOCKER_CMD        = docker run -p 1234:1234 -it --rm
DOCKER_ARG_CURDIR = -v $(shell pwd):/work -w /work
DOCKER_ARG_TTY    = --privileged -v /dev:/dev
DOCKER_EXEC_QEMU  = qemu-system-aarch64 -s -S -M raspi3 -kernel kernel8.img

#Build
NAME = aarch64issue
TARGET_NONE = aarch64-unknown-none
TARGET_SOFTFLOAT = aarch64-unknown-none-softfloat
KERNEL = kernel8
KERNEL_IMAGE = kernel8.img


#######################################################################
# Targets
#######################################################################


softfloat:
	cargo xrustc --target=$(TARGET_SOFTFLOAT) --release -- --emit asm
	cp ./target/$(TARGET_SOFTFLOAT)/release/$(NAME) ./$(KERNEL)
	cargo objcopy -- --strip-all -O binary ./$(KERNEL) ./$(KERNEL_IMAGE)

none:
	cargo xrustc --target=$(TARGET_NONE) --release -- --emit asm
	cp ./target/$(TARGET_NONE)/release/$(NAME) ./$(KERNEL)
	cargo objcopy -- --strip-all -O binary ./$(KERNEL) ./$(KERNEL_IMAGE)

softfloat_debug:
	cargo xrustc --target=$(TARGET_SOFTFLOAT) -- --verbose --emit asm
	cp ./target/$(TARGET_SOFTFLOAT)/debug/$(NAME) ./$(KERNEL)
	cargo objcopy -- --strip-all -O binary ./$(KERNEL) ./$(KERNEL_IMAGE)

none_debug:
	cargo xrustc --target=$(TARGET_NONE) -- --verbose --emit asm
	cp ./target/$(TARGET_NONE)/debug/$(NAME) ./$(KERNEL)
	cargo objcopy -- --strip-all -O binary ./$(KERNEL) ./$(KERNEL_IMAGE)

clean:
	cargo clean
	-rm -f ./$(KERNEL)
	-rm -f ./$(KERNEL_IMAGE)
	-rm -f ./none.lst
	-rm -f ./softfloat.lst

qemu_none: none
	$(DOCKER_CMD) $(DOCKER_ARG_CURDIR) $(CONTAINER_UTILS) \
	$(DOCKER_EXEC_QEMU) -serial stdio

qemu_softfloat: softfloat
	$(DOCKER_CMD) $(DOCKER_ARG_CURDIR) $(CONTAINER_UTILS) \
	$(DOCKER_EXEC_QEMU) -serial stdio

objdump_none: none
	cargo objdump --target $(TARGET_NONE) -- -disassemble -print-imm-hex $(KERNEL) > none.lst

objdump_softfloat: softfloat
	cargo objdump --target $(TARGET_SOFTFLOAT) -- -disassemble -print-imm-hex $(KERNEL) > softfloat.lst
