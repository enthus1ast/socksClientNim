import sockets
import strutils
import math
import logging

var L = newConsoleLogger()
addHandler(L)


# type
#   socksVersion = enum
#     SOCKS4, SOCKS4A, SOCKS5

proc portToBytes(port:int): (char,char) =
  var byteHigh = math.floor(port / 256)
  var byteLow  = port mod 256
  return (char(byteHigh),char(byteLow))


proc ipToBytes(ip:string): seq[char] =
  result = @[]
  for each in split(ip,'.'):
    result.add( char(parseInt(each)) )
  return result

proc strToBytes(str:string): seq[char] = 
  result = @[]
  for each in str:
    result.add( char(each) )
  result.add(char(0x00)) # we have to terminate the str with 0x00 
  return result

# echo dnsToBytes("getip.111mb.de")

proc connectSocket(so:Socket,socksIp:string,socksPort:int) =
  try:
    so.connect(socksIp,TPort(socksPort))
    info("[+] Connected to SOCKS proxy server")
  except:
    error("[-] Could not reach SOCKS proxy server")
    raise

proc charArrToStr(ar:openArray[char]) : string=
  var outp = ""
  for each in ar:
    outp = outp & $each
  return outp


proc socks4(socksIp:string,socksPort:int,targetIp:string,targetPort:int) : Socket =
  discard """
    This returns a socket which is connected to the SOCKS proxy.
    The SOCKS handshake is done so the socket should be connected to the
    targetIP / targetPort


    version is either SOCKS4 SOCKS4a
    targetHostname only is used when socks `version` is SOCKS4a
    when you use targetHostname , targetIp is ignored
  """

  var so = socket()
  so.connectSocket(socksIp,socksPort)

  var port = portToBytes(targetPort)
  var ip   = ipToBytes(targetIp)

  # this is the socks header
  # 1: socks version (4 , 5 )
  # 2: make tcp connect
  # 3: port high part
  # 4: port low part
  # 5-8: ip addr
  # 9: is 0 when no username was supllied ( in our case always zero =) )
  var helo = [char(4), char(1), port[0], port[1] , ip[0], ip[1], ip[2], ip[3], char(0)]
  so.send(charArrToStr(helo)) # we send socks header

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



proc socks4a(socksIp:string,socksPort:int,targetDns:string,targetPort:int) : Socket =
  discard """
    This returns a socket which is connected to the SOCKS4a proxy.
    The SOCKS4a handshake is done so the socket should be connected to the
    targetDns / targetPort

    SOCKS4a is able to ask the proxy to resolve the DNS.
    This is able to connect to a tor .onion adress.
  """
  var so = socket()
  so.connectSocket(socksIp,socksPort)

  var port = portToBytes(targetPort)
  #var ip   = ipToBytes("0.0.0.1")  # when we use socks4a we have to use a dummy address

  var helo : seq[char] = @[]

  # field 0: SOCKS version number, 1 byte, must be 0x04 for this version
  helo.add(char(0x04))

  # field 1: command code, 1 byte:
  #   0x01 = establish a TCP/IP stream connection
  #   0x02 = establish a TCP/IP port binding
  helo.add(char(0x01))
  # field 2: network byte order port number, 2 bytes
  helo.add(char(port[0]))
  helo.add(char(port[1]))
  
  # field 3: deliberate invalid IP address, 4 bytes, first three must be 0x00 and the last one must not be 0x00
  helo.add(char(0x00) )
  helo.add(char(0x00))
  helo.add(char(0x00))
  helo.add(char(0x01))

  # field 4: the user ID string, variable length, terminated with a null (0x00)
  helo.add(char(0x00))
  # helo.add(char(0x00)  )
  # field 5: the domain name of the host we want to contact, variable length, terminated with a null (0x00)  
  for each in strToBytes(targetDns):
    helo.add(char(each))


  so.send(charArrToStr(helo)) # we send socks header

  var data:string = "LEER"
  var size: int = 8
  var timeout : int=20000
  discard so.recv(data,size,timeout)

  # check if server has established the connection to the remote host
  if data[0] == char(0) and data[1] == char(0x5a):
    info("[+] SOCKS4a server has successfully established the connection.")
  else:
    error("[-] SOCKS4a server does not connected us to our desired remotehost")
    raise

  return so # we return the connected socket for future use




proc GET(so: Socket,host:string) : string =
  discard """
    This makes a raw http get request, only for testing : )
    host is only changeing the http header.
    The socket has to be connected!
  """
  var httpGetHelo = "GET / HTTP/1.1\nHost: "&host&"\n\n"

  try:
    so.send(httpGetHelo)
    info "[+] successfully send http get to remote server"
  except:
    error "[-] something breaks whil sending get request"

  var data = "LEER"
  var size= 100000
  var timeout=20000
  try:
    var respLen = so.recv(data,size,timeout)
    info "[+] made get request over SOCKS got " & $respLen & " bytes"
  except:
    error "[-] something breaks while receiving data from remote http server"
  return data



when isMainModule:
  # var mySocket4  = socks4( # Dies ist SOCKS version 4. NUR tcp und IP adressen!
  #                         # Dies ist SOCKS v.4  NUR ip KEIN dns!!
  #                         socksIp   = "127.0.0.1" ,   # die IP des SOCKS proxy
  #                         socksPort = 6655 ,          # der port auf dem der SOCKS proxy lauscht
  #                         targetIp = "85.214.59.56" , # die ip des rechners zu dem verbunden werden soll
  #                         targetPort = 80             # der zielport des rechners zu dem verbunden werden soll
  #                       )
  # echo mySocket4.GET("getip.111mb.de")

  var mySocket4a  = socks4a( # Dies ist SOCKS version 4a. TCP und DNS. Sollte durch tor funktionieren
                          socksIp   = "127.0.0.1" ,   # die IP des SOCKS proxy
                          socksPort = 9050 ,          # der port auf dem der SOCKS proxy lauscht
                          targetDns = "getip.111mb.de" , # der dns des rechners zu dem verbunden werden soll
                          targetPort = 80             # der zielport des rechners zu dem verbunden werden soll
                        )  
  echo mySocket4a.GET("getip.111mb.de")
  
  echo "\nDONE"
