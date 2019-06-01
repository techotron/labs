import datetime
import sys

date = datetime.datetime.now()
python_version = sys.version_info

print('hello, the date is %s' % date)
print('python version is %s.%s.%s' % (python_version[0], python_version[1], python_version[2]))
