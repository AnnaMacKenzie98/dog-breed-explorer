FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY dog_api_pipeline.py .
CMD ["python", "dog_api_pipeline.py"]
