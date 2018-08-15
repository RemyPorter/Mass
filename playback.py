import RPi.GPIO as GPIO
import pygame.mixer as m
import time

GPIO.setmode(GPIO.BOARD)
m.init(44100)

intro = m.Sound('toto.ogg')
outro = m.Sound('outro.ogg')
m.music.load('mass.ogg')

def setup():
  GPIO.setup(35, GPIO.OUT)
  GPIO.setup(37, GPIO.IN)
  GPIO.output(35, GPIO.HIGH)

while True:
  print('Starting run')
  setup()
  intro.play()
  print('Waiting...')
  time.sleep(10)
  print("Checking pin state- ensure it's plugged in!")
  while(GPIO.input(37) != GPIO.HIGH):
    time.sleep(0.06)
  m.music.rewind()
  m.music.play(loops=-1)
  print('Playing loop')
  while(GPIO.input(37) == GPIO.HIGH):
    time.sleep(0.06)
  print('Playing outro')
  m.music.fadeout(450)
  outro.play()
  time.sleep(300)
  print('Waiting for reset')
  while(GPIO.input(37) == GPIO.LOW):
    time.sleep(0.06)
  print('Reset!')