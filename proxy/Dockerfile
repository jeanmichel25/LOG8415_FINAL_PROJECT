FROM python:3.11

WORKDIR /app
COPY . /app

RUN apt-get update && apt-get install -y iputils-ping
RUN pip install -r requirements.txt
  
EXPOSE 5000

CMD [ "python", "-u", "-m" , "flask", "run", "--host=0.0.0.0"]