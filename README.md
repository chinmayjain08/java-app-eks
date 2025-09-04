# Boardgame ListingWebApp

## Description --

**Board Game Database Full-Stack Web Application.**
This web application displays lists of board games and their reviews. While anyone can view the board game lists and reviews, they are required to log in to add/ edit the board games and their reviews. The 'users' have the authority to add board games to the list and add reviews, and the 'managers' have the authority to edit/ delete the reviews on top of the authorities of users.  

## Technologies

- Java
- Spring Boot
- Amazon Web Services(AWS) EC2
- Thymeleaf
- Thymeleaf Fragments
- HTML5
- CSS
- JavaScript
- Spring MVC
- JDBC
- H2 Database Engine (In-memory)
- JUnit test framework
- Spring Security
- Twitter Bootstrap
- Maven

# EKS Deployment with CI/CD and Monitoring

## 📌 Project Overview
This project sets up an **Amazon EKS cluster** (with private endpoint) to deploy a Java application along with supporting infrastructure for CI/CD and monitoring. The setup includes:

- **EKS Cluster** → Running the Java application.
- **Jenkins** → CI/CD pipeline
- **ECR** → Storing container images.
- **Nexus** → Storing application artifacts (JAR files).
- **SonarQube** → Code quality analysis.
- **Trivy** → Container vulnerability scanning.
- **Prometheus & Grafana** → Monitoring EKS workloads and EC2 instances.
- **IAM Roles & Security Groups** → For secure integration between services.

---

## ⚙️ High-Level Steps

### 1. Infrastructure Setup
- Provision a **VPC** with networking components required for EKS and supporting services.
- Launch supporting EC2 instances for:
  - **Jenkins** (CI/CD server)
  - **Nexus** (artifact store)
  - **SonarQube** (code analysis)
  - **Monitoring** (Prometheus + Grafana)
- Install required dependencies on each EC2 (Java, Docker, etc. as needed).

---

### 2. EKS Cluster Setup
- Create an **EKS Cluster** with a **private endpoint** for enhanced security.
- Launch **EKS worker nodes** (EC2 instances) and join them to the cluster.
- Configure **security groups**:
  - Allow worker nodes to communicate with the EKS control plane.
  - Allow inbound traffic for the application (via Load Balancer).
  - Open required ports for Jenkins, Nexus, SonarQube, and Grafana dashboards.

---

### 3. IAM Roles & Access Configuration
- Assign IAM roles with required permissions:
  - **Jenkins EC2** → Access to ECR (push/pull images), EKS (deploy manifests).
  - **EKS Cluster & Worker Nodes** → Permissions for ECR image pulls.
- Configure `kubectl` access for Jenkins EC2 by:
  - Updating kubeconfig with cluster details.
  - Associating the correct IAM role with cluster-admin permissions.

---

### 4. Jenkins CI/CD Pipeline
- Configure Jenkins with required plugins (Git, Docker, Kubernetes, SonarQube, etc.).
- Define a **Jenkinsfile** with pipeline stages:
  1. **Build** → Compile Java application (Maven/Gradle).
  2. **SonarQube Analysis** → Run code quality checks.
  3. **Trivy Scan** → Security vulnerability scan on Docker image.
  4. **Build & Push Image** → Push Docker image to **ECR**.
  5. **Store Artifact** → Upload JAR file to **Nexus**.
  6. **Deploy to EKS** → Apply Kubernetes manifests for the Java application.
- Configure Jenkins credentials for Nexus, SonarQube, and ECR.

---

### 5. Nexus Setup
- Install Nexus on its EC2 instance.
- Configure Maven repositories:
  - Hosted repository for storing artifacts (JARs).
  - Proxy repositories for dependencies.
- Update Maven `settings.xml` with Nexus credentials for publishing artifacts.

---

### 6. SonarQube Setup
- Install SonarQube on its EC2 instance.
- Configure Jenkins SonarQube plugin.
- Generate a **SonarQube token** for Jenkins integration.
- Add code quality checks as part of the pipeline.

---

### 7. Monitoring Setup

#### A. EKS Monitoring
- Install **Kube-Prometheus-Stack** via Helm inside the EKS cluster.
- Expose Grafana using a LoadBalancer service for external access.
- Configure Grafana dashboards for:
  - Cluster health
  - Application workloads
  - Node performance

#### B. EC2 Monitoring
- Install **Node Exporter** on Jenkins, Nexus, SonarQube, and Monitoring EC2s.
- Configure Prometheus (on Monitoring EC2) to scrape metrics from all EC2 instances.
- Use Grafana (on Monitoring EC2) to visualize system metrics.

---

### 8. Security Group Rules (Summary)
- **Jenkins EC2**:
  - Allow HTTP/HTTPS (8080/443).
  - Allow SSH for admin access.
- **Nexus EC2**:
  - Allow HTTP/HTTPS (8081/443).
- **SonarQube EC2**:
  - Allow HTTP (9000).
- **Monitoring EC2**:
  - Allow Grafana UI (3000).
  - Allow Prometheus UI (9090).
- **EKS Worker Nodes**:
  - Allow inbound traffic from Load Balancer (80/443).
  - Allow inter-node communication.
  - Allow access to EKS control plane.

---

## ✅ Final Outcome
- Java application deployed on **EKS Cluster** with private endpoint.
- Automated CI/CD pipeline via **Jenkins**:
  - Build → Code Analysis → Security Scan → ECR Push → Nexus Store → Deploy.
- Monitoring with **Prometheus + Grafana**.
- Secure IAM role-based access without hardcoded secrets.

---

## Features

- Full-Stack Application
- UI components created with Thymeleaf and styled with Twitter Bootstrap
- Authentication and authorization using Spring Security
  - Authentication by allowing the users to authenticate with a username and password
  - Authorization by granting different permissions based on the roles (non-members, users, and managers)
- Different roles (non-members, users, and managers) with varying levels of permissions
  - Non-members only can see the boardgame lists and reviews
  - Users can add board games and write reviews
  - Managers can edit and delete the reviews
- Deployed the application on AWS EC2
- JUnit test framework for unit testing
- Spring MVC best practices to segregate views, controllers, and database packages
- JDBC for database connectivity and interaction
- CRUD (Create, Read, Update, Delete) operations for managing data in the database
- Schema.sql file to customize the schema and input initial data
- Thymeleaf Fragments to reduce redundancy of repeating HTML elements (head, footer, navigation)

## How to Run

1. Clone the repository
2. Open the project in your IDE of choice
3. Run the application
4. To use initial user data, use the following credentials.
  - username: bugs    |     password: bunny (user role)
  - username: daffy   |     password: duck  (manager role)
5. You can also sign up as a new user and customize your role to play with the application! 😊
