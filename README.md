# SOCKS4 / SOCKS4a client in nim


This implements a SOCKS4 proxy client.


features:
  * socks4  ( tcp only ip  )
  * socks4a ( tcp only dns )
    - Should work with tor

## socks4
the `socks4` proc will return a nim socket, wich has done
the socks4 handshake (https://en.wikipedia.org/wiki/SOCKS)
(be aware that socks4 can only handle ip addresses)

## socks4a
the `socks4a` proc will return a nim socket, wich has done
the socks4a handshake (https://en.wikipedia.org/wiki/SOCKS)
(this should work with tor)



->> This is a demonstration. Nothing serious. <<-
                  Handle with care!
