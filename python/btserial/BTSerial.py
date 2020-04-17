from bluetooth import *

from .BTConn import BTConn
from .exceptions import *

class BTSerial:
    def __init__(self, uuid = "00001101-0000-1000-8000-00805f9b34fb"):
        self.uuid = uuid
        self.sock = BluetoothSocket(RFCOMM)
        self.sock.bind(("", PORT_ANY))

    def listen(self):
        try:
            self.sock = BluetoothSocket(RFCOMM)
            self.sock.bind(("", PORT_ANY))
            self.sock.listen(1)
        
            port = self.sock.getsockname()[1]
        except IOError:
            raise BTInitError('error setting BT up')

        try:
            advertise_service(
                self.sock, "RoboticRemote",
                service_id = self.uuid,
                service_classes = [ self.uuid, SERIAL_PORT_CLASS ],
                profiles = [ SERIAL_PORT_PROFILE ],
                )
        except IOError:
            raise AdvertiseError('error advertising serial service %s' % self.uuid)

    def accept(self):
        try:
            sock, client_info = self.sock.accept()
            return BTConn(sock)
        except IOError:
            raise AcceptError('accept error')

    def close(self):
        self.sock.close()