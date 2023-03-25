FROM openjdk:17-jdk-slim

# Set the working directory to /app
WORKDIR /app

# Copy the Spring PetClinic application from the host to the container
ADD https://github.com/spring-projects/spring-petclinic/archive/master.tar.gz /app

# Extract the application archive
RUN tar -xvf master.tar.gz && mv spring-petclinic-master spring-petclinic && rm master.tar.gz

# Set the MySQL database configuration using environment variables
ENV SPRING_DATASOURCE_URL=jdbc:mysql://:3306/petclinic?useSSL=false&serverTimezone=UTC
ENV SPRING_DATASOURCE_USERNAME=petclinic
ENV SPRING_DATASOURCE_PASSWORD=petclinic
# Build the Spring PetClinic application
RUN ./mvnw package -DskipTests


# Expose port 8080
EXPOSE 8080

# Set the command to run the Spring PetClinic application when the container starts
CMD ["java", "-jar", "target/spring-petclinic-2.5.0.jar"]