from .BTSerial import BTSerial
from .BTConn import BTConn
from .exceptions import (
    BTException, BTInitError, AdvertiseError,
    ListenError, Timeout, ConnectionError,
    AcceptError, ClosedError, SendError,
    RecvError, SendTimeout, ReceiveTimeout,
    DataError,
)

__title__ = 'btserial'
__versioninfo__ = (1, 0, 0)
__version__ = '.'.join(map(str, __versioninfo__))
