FROM python:3.7.5-slim-buster

WORKDIR /batman
COPY batman/requirments.txt ./
RUN pip install --no-cache-dir -r requirments.txt

COPY batman/ ./

CMD [ "python", "./techops.py" ]
