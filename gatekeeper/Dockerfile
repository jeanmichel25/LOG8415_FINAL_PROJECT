FROM python:3.11

WORKDIR /app
COPY . /app

RUN pip install -r requirements.txt
  
EXPOSE 5000

CMD [ "python", "-u", "-m" , "flask", "run", "--host=0.0.0.0"]