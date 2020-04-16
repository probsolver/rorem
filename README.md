# about

Mobile remote for robotic projects.

# install

Enable installation from "unknown sources" on your Android phone, download apk from Releases page, and install by opening in file manager.
# server side

See steps 1-3 here: https://scribles.net/setting-up-bluetooth-serial-port-profile-on-raspberry-pi/ 
Python example heavily inspired by pyBluez server example:

```python
from bluetooth import *
from struct import *

def encode(key, value):
    return pack('!Bi', key, value)

def decode(data):
    if len(data) < 5:
        return (0, 0, data)
    (key, value) = unpack_from('!Bi', data)
    return (key, value, data[5:])
    

server_sock=BluetoothSocket( RFCOMM )
server_sock.bind(("",PORT_ANY))
server_sock.listen(1)

port = server_sock.getsockname()[1]

uuid = "00001101-0000-1000-8000-00805f9b34fb"

advertise_service( server_sock, "SampleServer",
                   service_id = uuid,
                   service_classes = [ uuid, SERIAL_PORT_CLASS ],
                   profiles = [ SERIAL_PORT_PROFILE ], 
#                   protocols = [ OBEX_UUID ] 
                    )
                   
print("Waiting for connection on RFCOMM channel %d" % port)

while True:
    buf = b'';
    sock, client_info = server_sock.accept()
    print("Accepted connection from ", client_info)

    try:
        while True:
            try:
                sock.settimeout(5.0)
                r = sock.recv(1024)
                sock.settimeout(None)
                print("received [%s]" % r)
                if len(r) == 0:
                    break
                buf += r
                while len(buf) >= 5:
                    (key, value, rest) = decode(buf)
                    buf = rest
                    if key == 0:
                        print('error decoding data')
                    else:
                        print('key: %d, value %d' % (key, value))
                        sock.send(encode(key,value))
            except BluetoothError as e:
                if str(e) == 'timed out':
                    print('timeout')
                else:
                    print('disconnected')
                    break
    except IOError:
        sock.close()
        print("error: disconnected")

print('stopped')
server_sock.close()
print("done")
```
