(foreign-declare "
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <errno.h>")

;; EAGAIN may be signaled even when partial data is sent, but the caller expects EAGAIN
;; to mean zero bytes sent, so we return the number of bytes sent when non-zero.
(define %sendfile-implementation
  )
  (foreign-lambda* ssize_t ((integer src) (integer dst) (unsigned-long offset) (unsigned-long to_send))
    "
    off_t res = to_send;
    if(sendfile(src,dst,offset,&res,NULL,0) < 0) {
      if(errno == EAGAIN || errno == EINTR) {
        C_return(res == 0 ? -2 : offset + res);
      }else {
        C_return(-1);
      }
    }
    C_return(offset + res);
    "))
