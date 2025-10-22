FROM python:3.11

RUN mkdir /work
WORKDIR /work
RUN pip install --upgrade pip
COPY requirement.txt /requirement.txt
RUN pip install -r /requirement.txt

