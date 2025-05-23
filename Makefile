.PHONY: all kernel_source_index pick_up_latest clean download_kernel_source extract_and_configure_kernel install_deps prepare_rootfs

default: all

install_deps: 
	@apt install flex bison libelf-dev libssl-dev curl build-essential git libxml2-utils cpio -y

kernel_source_index: install_deps
	@# Download kernel index from kernel.org
	@curl -s https://kernel.org/ -o kernel_source_index.html
	@# Extract table content with id 'releases' from the XML file
	@xmllint --html --xpath '//table[@id="releases"]' kernel_source_index.html > releases_table.xml 2>/dev/null
	@# Extract tag contents with inner text 'tarball' from releases_table.xml
	@xmllint --xpath "//table/tr/td[contains(text(),':')]|//table/tr/td/strong|//*[contains(text(),'tarball')]|//*[contains(@href,'next-')]" releases_table.xml > tarball_links.txt 2>/dev/null

pick_up_latest: kernel_source_index
	@# Pick up the latest stable kernel info line from ./getkrnlrel output
	@./getkrnlrel --no-header | grep "${KERNEL_CHANNEL}" | head -n 1 > latest_kernel.txt
	@echo "Selected Kernel Version: $$(cat ./latest_kernel.txt | awk '{print $$2}' | sed -n 'p')"

download_kernel_source: pick_up_latest
	@curl $(shell cat latest_kernel.txt | awk '{print $$3}') -o kernel.tar.xz

kernel.tar.xz: download_kernel_source
	@echo Kernel sources download successfully.

extract_and_configure_kernel: kernel.tar.xz
	@tar -xvf kernel.tar.xz
	@cd linux-* && cp ../kernel.config .config

prepare_rootfs: 
	@./init_rootfs rootfs 1400 ext4 1
	@cd linux-* && sed -ne 's@/rootfs@$(shell pwd)/rootfs@g' -e 'p' ../kernel.config > .config

bzImage.efi: prepare_rootfs
	@cd linux-* && make -j 1
	@cp linux-*/arch/x86/boot/bzImage bzImage.efi
	@cp bzImage.efi /mnt/e/bzImage.efi
	@umount rootfs

clean:
	@rm -f kernel_source_index.html releases_table.xml tarball_links.txt latest_kernel.txt bzImage.efi kernel.tar.xz bzImage.efi
	@rm -rvf linux-*	
	@rm -rvf rootfs

all: install_deps extract_and_configure_kernel prepare_rootfs bzImage.efi
	@echo "All done!"
