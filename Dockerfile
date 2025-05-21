# Use an official Python image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Copy project files
COPY requirements.txt .
COPY app.py .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the Flask port
EXPOSE 5000

# Run the Flask app
CMD ["python", "app.py"]
