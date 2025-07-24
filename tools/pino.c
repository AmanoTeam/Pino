#include <stddef.h>
#include <errno.h>

#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>

void* mmap64(void* __addr, size_t __size, int __prot, int __flags, int __fd, off64_t __offset) {
	
	int __mmap2_shift = 12; /* 2**12 == 4096 */
	
	const int page_size = getpagesize();
	
	if (page_size == 16384) {
		__mmap2_shift += 2; /* 2**14 == 16384 */
	}
	
	if (__offset < 0 || (__offset & ((1UL << __mmap2_shift) - 1)) != 0) {
		errno = EINVAL;
		return MAP_FAILED;
	}

	// prevent allocations large enough for `end - start` to overflow
	size_t __rounded = __BIONIC_ALIGN(__size, page_size);
	
	if (__rounded < __size || __rounded > PTRDIFF_MAX) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

	extern void* __mmap2(void* __addr, size_t __size, int __prot, int __flags, int __fd, size_t __offset);
	
	return __mmap2(__addr, __size, __prot, __flags, __fd, __offset >> __mmap2_shift);
	
}
