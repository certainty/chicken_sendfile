;; 
;; %%HEADER%%
;; 

(use test)
(load "test-helper")
(use sendfile)


(with-running-server

 (let* ((mb-buffer (generate-buffer (mebibytes 1)))
        (mb-checksum (buffer-checksum mb-buffer)))


   (define (stream-mb-buffer)
     (call-with-temporary-file/checksum
      mb-buffer
      (lambda (temp-file _)
        (stream-file temp-file sendfile))))
 
   (test-group "sendfile main interface"
               
               (test "sendfile" mb-checksum (stream-mb-buffer)))

   (test-group "forcing implementation"
               
               (parameterize ((force-implementation 'read-write))
                 (test "read-write" mb-checksum (stream-mb-buffer)))

               (if sendfile-available
                   (parameterize ((force-implementation 'sendfile))
                     (test "sendfile(2)" mb-checksum (stream-mb-buffer))))

               (if mmap-available
                   (parameterize ((force-implementation 'mmapped))
                     (test "mmap(2)" mb-checksum (stream-mb-buffer))))

               (parameterize ((force-implementation 'read-write-port))
                 (test "read-write-port" mb-checksum (stream-mb-buffer))))


   (test-group "read-write variations"
               
               (call-with-temporary-file/checksum
                (generate-buffer (mebibytes 1))
                (lambda (temp-file expected-checksum)
                  (test "ports only"
                        expected-checksum
                        (call-with-connection-to-server
                         (lambda (server-in server-out)
                           (write-content-size server-out (mebibytes 1))
                           (call-with-input-file temp-file
                             (lambda (file-in)
                               (sendfile file-in server-out)))
                           (read-checksum server-in)))))))


   (test-group "content chunking")   

   (test-group "bugs"               
               (call-with-buffer/checksum
                (kibibytes 1)
                (lambda (buffer checksum)
                  (test "custom input port without fd [bug #542]"
                        checksum
                        (call-with-connection-to-server
                         (lambda (server-in server-out)
                           (write-content-size server-out (kibibytes 1))
                           (sendfile (open-input-string buffer) server-out)
                           (read-checksum server-in))))))
   
    
               (call-with-temporary-file/checksum
                (generate-buffer (mebibytes 2))
                (lambda (temp-file expected-checksum)
                  (test "send files > 1 mibibyte"
                        expected-checksum
                        (stream-file temp-file sendfile)))))))

(unless (zero? (test-failure-count)) (exit 1))

