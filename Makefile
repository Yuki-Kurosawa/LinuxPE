.PHONY: all kernel_source_index pick_up_latest clean download_kernel_source extract_and_configure_kernel install_deps

default: all

kernel_source_index:
	@# Download kernel index from kernel.org
	curl -s https://kernel.org/ -o kernel_source_index.html
	@# Extract table content with id 'releases' from the XML file
	xmllint --html --xpath '//table[@id="releases"]' kernel_source_index.html > releases_table.xml 2>/dev/null
	@# Extract tag contents with inner text 'tarball' from releases_table.xml
	xmllint --xpath "//table/tr/td[contains(text(),':')]|//table/tr/td/strong|//*[contains(text(),'tarball')]|//*[contains(@href,'next-')]" releases_table.xml > tarball_links.txt 2>/dev/null

pick_up_latest: kernel_source_index
	@# Pick up the latest stable kernel info line from ./getkrnlrel output
	./getkrnlrel --no-header | grep 'stable' | head -n 1 > latest_stable_kernel.txt
	@echo "Selected Kernel Version: $$(cat ./latest_stable_kernel.txt | awk '{print $$2}' | sed -n 'p')"

download_kernel_source: pick_up_latest
	curl -s $(shell cat latest_stable_kernel.txt | awk '{print $$3}') -o kernel.tar.xz

extract_and_configure_kernel: download_kernel_source
	tar -xvf kernel.tar.xz
	cd linux-* && cp ../kernel.config .config

install_deps:
	apt install flex bison libelf-dev libssl-dev -y

bzImage.efi: install_deps
	cd linux-* && make -j$$(nproc)
	cp linux-*/arch/x86/boot/bzImage bzImage.efi

clean:
	rm -f kernel_source_index.html releases_table.xml tarball_links.txt latest_stable_kernel.txt bzImage.efi kernel.tar.xz

all: bzImage.efi
	@echo "All done!"