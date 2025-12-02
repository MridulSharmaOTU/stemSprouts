# Start with a slim and secure Python base image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the dependency list into the container
COPY requirements.txt .

# Install dependencies from requirements.txt
# We also install uvicorn as it is the standard for running FastAPI in production.
RUN pip install --no-cache-dir -r requirements.txt uvicorn

# Copy the application source code into the container
COPY . .

# Expose the port that the application will run on
EXPOSE 8000

# Command to run the application using uvicorn
# The --host 0.0.0.0 flag makes the app accessible from outside the container.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
