#include <errno.h>
#include <sys/types.h>

#include "fstream.h"

int truncate(
	const char* path,
	off_t length
) {
	
	int cerrno = 0;
	
	fstream_t* stream = NULL;
	int status = FSTREAM_SUCCESS;
	
	stream = fstream_open(path, FSTREAM_TRUNCATE);
	
	if (stream == NULL) {
		return -1;
	}
	
	status = fsream_truncate(stream, length);
	
	cerrno = errno;
	
	fstream_close(stream);
	
	if (status != FSTREAM_SUCCESS) {
		return -1;
	}
	
	return 0;
	
}
