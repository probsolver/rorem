from btserial import *

bt = BTSerial()
print('BT initialized')
bt.listen()
print('Waiting for connections')

while True:
        conn = bt.accept()
        if conn is None:
            continue

        while True:
            try:
                conn.recv(timeout = 1.0)
            except Timeout as e:
                pass
            except DataError as de:
                print('bad data: %s' % str(de))
                break
        
            print(conn.values.items())
            try:
                # if len(conn.values) > 0:
                #    conn.send(conn.values.items(), timeout = 1.0)
                conn.send([(1, 11), (2, 22)])
            except SendError as se:
                print('cannot send: %s' % str(se))
                break
        
        conn.close()

print('stopping')
bt.close()
print('done')