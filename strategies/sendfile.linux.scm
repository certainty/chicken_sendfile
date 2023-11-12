(foreign-declare "
#include <sys/sendfile.h>
#include <fcntl.h>
#include<errno.h>")

(define %sendfile-implementation
  (foreign-lambda* ssize_t ((integer src) (integer dst) (unsigned-long offset) (unsigned-long to_send))
    "
    off_t res = offset;
    if(sendfile(dst,src,&res,to_send) < 0) {
      if(errno == EAGAIN || errno == EINTR) {
        C_return(res == 0 ? -2 : res);
      }else{
        C_return(-1);
      } 
    }
    C_return(res);
    "))


