# Use an official lightweight Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for YOLOv8 (OpenCV, torch, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose port 7860 for Hugging Face Spaces
EXPOSE 7860

# Use Gunicorn to serve the FastAPI or Flask app
CMD ["gunicorn", "--bind", "0.0.0.0:7860", "model_api:app"]
