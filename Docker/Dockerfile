FROM openjdk:17-jdk-slim
WORKDIR /app

# Clone the Spring PetClinic repository
RUN apk add --no-cache git && \
    git clone https://github.com/spring-projects/spring-petclinic.git

# Set the working directory to /app/spring-petclinic
WORKDIR /app/spring-petclinic

# Build the Spring PetClinic application
RUN ./mvnw package -DskipTests

# Expose port 8080
EXPOSE 8080

# Set the command to run the Spring PetClinic application when the container starts
CMD ["java", "-jar", "target/spring-petclinic-2.5.0.jar"]