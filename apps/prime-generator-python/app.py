import random

from datetime import datetime
from flask import Flask

def is_prime(num):
    if num <= 1:
        return False
    if num <= 3:
        return True
    if num % 2 == 0 or num % 3 == 0:
        return False
    i = 5
    while i * i <= num:
        if num % i == 0 or num % (i + 2) == 0:
            return False
        i += 6
    return True

def nth_prime(n):
    count = 0
    num = 2
    while count < n:
        if is_prime(num):
            count += 1
            if count == n:
                return num
        num += 1


app = Flask(__name__)

@app.route('/')
def generate_random_prime():
    start = datetime.now()
    # this should take somewhere between 1/10th of a second and a few seconds 
    random_number = random.randint(10000, 100000)
    nth_prime_number = nth_prime(random_number)
    since = datetime.now() - start
    seconds = since.total_seconds()
    message = f"The {random_number}th prime number is: {nth_prime_number} found in {seconds} seconds"
    return message
