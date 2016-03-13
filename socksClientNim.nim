discard """
  This implements a SOCKS4 proxy client.
  the `socks4` proc will return a nim socket, wich has done
  the socks4 handshake (https://en.wikipedia.org/wiki/SOCKS)
  (be aware that socks4 can only handle ip addresses)

  This is a demonstration. Nothing serious.
  Handle with care!
"""


import sockets
import strutils
import math
import logging


var L = newConsoleLogger()
addHandler(L)

proc portToBytes(port:int): (char,char) =
  var byteHigh = math.floor(port / 256)
  var byteLow  = port mod 256
  return (char(byteHigh),char(byteLow))


proc ipToBytes(ip:string): seq[char] =
  result = @[]
  for each in split(ip,'.'):
    result.add( char(parseInt(each)) )
  return result


#def portToBytes(port:int): (char,char) =



proc socks4(socksIp:string,socksPort:int,targetIp:string,targetPort:int) : Socket =
  discard """
    This returns a socket which is connected to the SOCKS proxy.
    The SOCKS handshake is done so the socket should be connected to the
    targetIP / targetPort
  """


  var so = socket()
  try:
    so.connect(socksIp,TPort(socksPort))
    info("[+] Connected to SOCKS proxy server")
  except:
    error("[-] Could not reach SOCKS proxy server")
    raise

  var port = portToBytes(targetPort)
  var ip   = ipToBytes(targetIp)

  # this is the socks header
  # 1: socks version (4 , 5 )
  # 2: connection attempt
  # 3: port high part
  # 4: port low part
  # 5-8: ip addr
  # 9: is 0 when no username was supllied ( in our case always zero =) )
  var helo = [char(4), char(1), port[0], port[1] , ip[0], ip[1], ip[2], ip[3], char(0)]

  var outp = ""

  for each in helo:
    outp = outp & $each

  so.send(outp) # we send socks header

  var data:string = "LEER"
  var size: int = 8
  var timeout : int=1000
  discard so.recv(data,size,timeout)

  # check if server has established the connection to the remote host
  if data[0] == char(0) and data[1] == char(90):
    info("[+] SOCKS server has successfully established the connection.")
  else:
    error("[-] SOCKS server does not connected us to our desired remotehost")
    raise

  return so # we return the connected socket for future use

proc GET(so: Socket,host:string) : string =
  discard """
    This makes a raw http get request, only for testing : )
    host is only changeing the http header.
    The socket has to be connected!
  """
  var httpGetHelo = "GET / HTTP/1.1\nHost: "&host&"\n\n"
  so.send(httpGetHelo)

  var data = "LEER"
  var size= 100000
  var timeout=5000
  try:
    var respLen = so.recv(data,size,timeout)
    info "[+] made get request over SOCKS got " & $respLen & " bytes"
  except:
    info "[-] something breaks while makeing get request"
  return data



when isMainModule:
  var mySocket  = socks4( # Dies ist SOCKS version 4. NUR tcp und IP adressen!
                          # Dies ist SOCKS v.4  NUR ip KEIN dns!!
                          socksIp   = "127.0.0.1" ,   # die IP des SOCKS proxy
                          socksPort = 9999 ,          # der port auf dem der SOCKS proxy lauscht
                          targetIp = "85.214.59.56" , # die ip des rechners zu dem verbunden werden soll
                          targetPort = 80             # der zielport des rechners zu dem verbunden werden soll
                        )
  echo mySocket.GET("getip.111mb.de")
  echo "\nDONE"
  #discard readLine(stdin)
