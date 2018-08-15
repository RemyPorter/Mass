# Simple script to convert a spreadsheet of numbers into audio
# uses Mac `say` command, so it's not portable
import csv
from num2words import num2words
import subprocess

i = 0
with open('mass.csv', 'r') as f:
  reader = csv.reader(f)
  for row in reader:
    line = []
    for cell in row:
      cell = cell.strip()
      try:
        f = float(cell)
        line.append(num2words(f))
      except:
        if cell:
          line.append(cell)
        else:
          line.append('[[slnc 1000]]')
    fname = 'sounds/' + str(i).rjust(3, '0') + '.aiff'
    statement = '"' + ' [[slnc 500]] '.join(line) + '"'
    subprocess.call(['say', '-v', 'Sin-Ji', statement, '-o', fname])