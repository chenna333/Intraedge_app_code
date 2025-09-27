# Stage 1: Build the Java app using Maven
FROM maven:3.9.2-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code and build the app
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create lightweight image with only the JAR
FROM eclipse-temurin:17-jre-alpine

# Set working directory
WORKDIR /app

# Copy the JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port (adjust to your app port)
EXPOSE 8080

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
