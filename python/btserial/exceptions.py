class BTException(IOError):
    def __init__(self, *args, **kwargs):
        super(BTException, self).__init__(*args, **kwargs)

class BTInitError(BTException):
    """BT init error"""

class AdvertiseError(BTInitError):
    """service advertisement failed"""

class ListenError(BTException):
    """listen call failed"""

class Timeout(BTException):
    """network IO timed out"""

class ConnectionError(BTException):
    """generic connection problem"""

class AcceptError(ConnectionError):
    """accept call error"""

class ClosedError(ConnectionError):
    """connection closed"""

class SendError(ConnectionError):
    """send operation failed"""

class RecvError(ConnectionError):
    """recv operation failed"""

class SendTimeout(ConnectionError, Timeout):
    """timeout on send"""

class ReceiveTimeout(ConnectionError, Timeout):
    """timeout on recv"""

class DataError(BTException):
    """invalid data received"""