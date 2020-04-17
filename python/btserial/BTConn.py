from struct import *
from bluetooth import BluetoothError
from .exceptions import *

class BTConn:
    _buf = b''
    _values = {}
    _sock = None
    timeout_handler = None

    def __init__(self, sock, timeout_handler = None):
        self._sock = sock
        self.timeout_handler = timeout_handler

    @property
    def values(self):
        return self._values

    def set_timeout_handler(self, tm_handler):
        self.timeout_handler = tm_handler

    @staticmethod
    def encode(value):
        (k, v) = value
        try:
            return (pack('!Bi', k, v), 5)
        except struct.error:
            return (None, 0)

    @staticmethod
    def decode(data):
        if len(data) < 5:
            return (None, 0)
        try:
            result = unpack_from('!Bi', data)
        except struct.error:
            return (None, 5)
        return (result, 5)

    def recv(self, timeout = 1.0):
        try:
            self._sock.settimeout(timeout)
            r = self._sock.recv(1024)
            self._sock.settimeout(None)
            l = len(r)
            if l == 0:
                return 0
            # print('dbg recvd %d [%s]' % (l, r))
            self._buf += r
            b = len(self._buf)
            while b > 0:
                (dec, n) = self.decode(self._buf)
                if n == 0:
                    break
                if dec is None:
                    raise DataError('invalid data/decode failed [%s]' % _buf[:5])
                else:
                    (k, v) = dec
                    self._values[k] = v
                    self._buf = self._buf[n:]
                    b -= n
            return l
        except BluetoothError as e:
            if str(e) == 'timed out':
                if self.timeout_handler is not None:
                    try:
                        self.timeout_handler(self)
                        return 0
                    except:
                        pass
                raise ReceiveTimeout('recv timeout')
            else:
                raise RecvError(str(e))

    def send(self, vals, timeout = 1.0):
        try:
            nn = 0
            for value in vals:
                (data, n) = self.encode(value)
                nn += n
                if data is None:
                    raise ValueError('bad value to send')
                if data is not None:
                    self._sock.settimeout(timeout)
                    self._sock.send(data)
                    self._sock.settimeout(None)
            return nn
        except BluetoothError as e:
            if str(e) == 'timed out':
                raise SendTimeout('send timeout')
            raise SendError(str(e))

    def close(self):
        self._sock.close()