FROM python:3.12-slim-bookworm

WORKDIR /usr/src/app
COPY Pipfile ./
COPY Pipfile.lock ./
RUN pip install --no-cache-dir pipenv && pipenv install
COPY *.py .
CMD [ "pipenv", "run", "python", "-m", "flask", "run", "--host=0.0.0.0", "-p 8888" ]