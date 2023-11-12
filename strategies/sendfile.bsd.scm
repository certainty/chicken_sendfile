(foreign-declare "
#include <errno.h>
#include<sys/socket.h>
#include<sys/types.h>
#include <sys/uio.h>")

(define %sendfile-implementation
  )
  (foreign-lambda* ssize_t ((integer src) (integer dst) (unsigned-long offset) (unsigned-long to_send))
    "
    off_t res = 0;
    if(sendfile(src,dst,offset,to_send,NULL,&res,0) < 0) {
      if(errno == EAGAIN || errno == EINTR) {
        C_return(res == 0 ? -2 : offset + res);
      }else{
        C_return(-1);
      } 
    }
    C_return(offset + res);
    "))
