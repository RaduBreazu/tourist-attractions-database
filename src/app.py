from dataclasses import dataclass

from functools import reduce
import matplotlib.pyplot as plt
import numpy as np

import cx_Oracle

@dataclass
class Connection:
    conn : cx_Oracle.Connection
    cursor : cx_Oracle.Cursor

def openConnection(host, port, service_name, user, password) -> Connection:
    dsn = cx_Oracle.makedsn(host, port, service_name)
    connection = cx_Oracle.connect(user, password, dsn)
    cursor = connection.cursor()
    return Connection(connection, cursor)

def closeConnection(connection : Connection):
    connection.cursor.close()
    connection.conn.close()

def executeQuery(connection : Connection, query : str) -> list[any] | None:
    try:
        connection.cursor.execute(query)
        return connection.cursor.fetchall()
    except cx_Oracle.Error as error:
        print(error)
        return None
    
def callFunction(connection : Connection, name : str, args : list[any]) -> list[any] | None:
    try:
        result_cursor = connection.cursor.callfunc(name, cx_Oracle.CURSOR, args)
        return result_cursor.fetchall()
    except cx_Oracle.Error as error:
        print(error)
        return None

def show(data : list[any]) -> str:
    f = lambda x : 'NULL' if x is None else x
    list_str = list(map(lambda x: f'{f(x[0])}, {f(x[1])}', data))
    return reduce(lambda x, y: x + '\n' + y, list_str)

def plot_most_common_destinations(conn : Connection, n : int):
    result = callFunction(conn, 'TRENDING_DESTINATIONS', [n])
    
    # plot result
    plt.rcParams["figure.figsize"] = (8, 6)
    x_axis = np.arange(len(result))
    width = 0.5
    plt.bar(x_axis, list(map(lambda x: x[1], result)), width)
    plt.xticks(x_axis, list(map(lambda x: x[0], result)))
    plt.xlabel('Destinations')
    plt.ylabel('Number of prospecting tourists')
    plt.title('Most popular destinations right now')
    plt.show()

def main():
    conn = openConnection('localhost', 1521, 'xe', 'system', 'parolaAiaPuternica!')
    plot_most_common_destinations(conn, 5)
    closeConnection(conn)

if __name__ == '__main__':
    main()