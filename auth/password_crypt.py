import crypt
import os
import string
import getpass

try:  # 3.6 or above
    from secrets import choice as randchoice
except ImportError:
    from random import SystemRandom
    randchoice = SystemRandom().choice

def sha512_crypt(password, salt=None, rounds=None):
    if salt is None:
        salt = ''.join([randchoice(string.ascii_letters + string.digits)
                        for _ in range(8)])

    prefix = '$6$'
    if rounds is not None:
        rounds = max(1000, min(999999999, rounds or 5000))
        prefix += 'rounds={0}$'.format(rounds)
    return crypt.crypt(password, prefix + salt)

password = getpass.getpass('Password:')

encrypted = sha512_crypt(password, rounds=25000)

print(encrypted)
