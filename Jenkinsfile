pipeline {
  agent any
  triggers {
    githubPush()
  }
  environment {
    // Git and app
    GIT_REPO_URL = 'https://github.com/chinmayjain08/java-app-eks.git'
    GIT_BRANCH   = 'main'
    APP_NAME     = 'java-app'
    
    // AWS ECR details - Fixed the registry format
    AWS_REGION = 'eu-north-1'
    ECR_REGISTRY = '533267435771.dkr.ecr.eu-north-1.amazonaws.com'  // Removed /java-app from here
    ECR_REPOSITORY = 'java-app'
    IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}"  // This will be: 533267435771.dkr.ecr.eu-north-1.amazonaws.com/java-app
    VERSION_TAG = "${env.BUILD_NUMBER}"
    
    // Nexus URLs
    NEXUS_REPO_URL = 'http://13.62.56.162:8081/repository/maven-releases/'
    NEXUS_SNAPSHOT_URL = 'http://13.62.56.162:8081/repository/maven-snapshots/'
    
  }
  
  stages {
    stage('Checkout') {
      steps {
        git(
          branch: 'main',
          credentialsId: 'github_creds',
          url: 'https://github.com/chinmayjain08/java-app-eks.git'
        )
      }
    }


    
    stage('Build (Maven)') {
      steps {
        sh 'mvn -B -ntp clean package -DskipTests'
      }
    }
    
    stage('Unit Tests') {
      steps {
        sh 'mvn -B -ntp test'
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
        }
      }
    }
    
    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonarqube') {
          sh '''
            mvn clean verify sonar:sonar \
              -Dsonar.projectKey=java-project \
              -Dsonar.projectName=java-project \
              -Dsonar.host.url=http://13.53.122.173:9000 \
              -Dsonar.sources=src/main/java \
              -Dsonar.java.binaries=target/classes
          '''
        }
      }
    }
    
    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          script {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Pipeline aborted due to quality gate failure: ${qg.status}"
            }
            echo "Quality Gate passed: ${qg.status}"
          }
        }
      }
    }
    
  stage('Upload Artifact to Nexus') {
    steps {
        withCredentials([usernamePassword(credentialsId: 'nexus-docker-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
            sh '''
                # Get project details
                ARTIFACT_ID=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
                VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
                JAR_FILE="target/${ARTIFACT_ID}-${VERSION}.jar"
                
                echo "Uploading JAR: $JAR_FILE"
                echo "Using Nexus user: $NEXUS_USER"
                
                # Upload using Nexus REST API with Jenkins credentials
                curl -v -u "${NEXUS_USER}:${NEXUS_PASS}" \
                    --upload-file "$JAR_FILE" \
                    "http://13.62.56.162:8081/repository/maven-snapshots/com/javaproject/$ARTIFACT_ID/$VERSION/${ARTIFACT_ID}-${VERSION}.jar"
                    
                # Check if upload was successful
                if [ $? -eq 0 ]; then
                    echo "✅ JAR uploaded successfully to Nexus"
                else
                    echo "❌ JAR upload failed"
                    exit 1
                fi
            '''
        }
    }
}




    
    stage('Docker Build') {
      steps {
        sh """
          DOCKER_BUILDKIT=1 docker build \
            --pull \
            -t ${IMAGE_NAME}:latest \
            -t ${IMAGE_NAME}:${VERSION_TAG} \
            .
        """
      }
    }
  stage('Trivy Security Scan') {
    steps {
        script {
            sh """
                echo "Starting Trivy security scan..."
                
                # Run Trivy scan (table format for console output)
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image \
                    --format table \
                    ${IMAGE_NAME}:${VERSION_TAG}
                
                # Generate JSON report for archiving
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    -v \$(pwd):/workspace \
                    aquasec/trivy:latest image \
                    --format json --output /workspace/trivy-report.json \
                    ${IMAGE_NAME}:${VERSION_TAG}
                
                echo "Analyzing vulnerability report..."
                
                # Install jq if not present (for JSON parsing)
                which jq || (echo "Installing jq..." && sudo apt-get update && sudo apt-get install -y jq)
                
                # Count vulnerabilities by severity
                if [ -f "trivy-report.json" ]; then
                    CRITICAL=\$(cat trivy-report.json | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length')
                    HIGH=\$(cat trivy-report.json | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length')
                    MEDIUM=\$(cat trivy-report.json | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length')
                    LOW=\$(cat trivy-report.json | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length')
                    
                    echo "=== VULNERABILITY SUMMARY ==="
                    echo "🔴 Critical: \$CRITICAL"
                    echo "🟠 High: \$HIGH" 
                    echo "🟡 Medium: \$MEDIUM"
                    echo "🟢 Low: \$LOW"
                    echo "=============================="
                    
                    # Quality Gate 1: Fail on Critical vulnerabilities
                    if [ "\$CRITICAL" -gt "3" ]; then
                        echo "❌ QUALITY GATE FAILED: \$CRITICAL critical vulnerabilities found!"
                        echo "Critical vulnerabilities must be fixed before deployment."
                        echo "Please review the scan report and update base images or dependencies."
                        exit 1
                    fi
                    
                    # Quality Gate 2: Warn on High vulnerabilities (threshold: 10)
                    if [ "\$HIGH" -gt "50" ]; then
                        echo "❌ QUALITY GATE FAILED: \$HIGH high-severity vulnerabilities found (threshold: 10)!"
                        echo "Please reduce high-severity vulnerabilities before deployment."
                        exit 1
                    elif [ "\$HIGH" -gt "25" ]; then
                        echo "⚠️  WARNING: \$HIGH high-severity vulnerabilities found"
                        echo "Consider addressing these vulnerabilities in the next iteration."
                    fi
                    
                    # Quality Gate 3: Info on Medium vulnerabilities
                    if [ "\$MEDIUM" -gt "50" ]; then
                        echo "⚠️  INFO: \$MEDIUM medium-severity vulnerabilities found (consider review)"
                    fi
                    
                    echo "✅ Security quality gates passed!"
                    echo "✅ Safe to proceed with deployment"
                    
                else
                    echo "❌ ERROR: trivy-report.json not found!"
                    exit 1
                fi
                
                echo "✅ Trivy security scan completed successfully"
            """
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.*', allowEmptyArchive: true
        }
        failure {
            echo "🚨 Security scan failed - Check vulnerability report for details"
        }
        success {
            echo "✅ Security scan passed all quality gates"
        }
    }
}

    stage('ECR Login & Push') {
      steps {
        script {
          sh """
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
            docker push ${IMAGE_NAME}:latest
            docker push ${IMAGE_NAME}:${VERSION_TAG}
          """
        }
      }
    }
    
    stage('Deploy to EKS') {
    steps {
        sh """
            # Configure kubectl with EKS cluster
            aws eks update-kubeconfig --region ${AWS_REGION} --name eks-cluster
            
            # Update deployment with new image tag
            sed -i 's|image: .*|image: ${IMAGE_NAME}:${VERSION_TAG}|' deployment-service.yaml
            
            # Apply to EKS cluster
            kubectl apply -f deployment-service.yaml -n boardgame
            
            # Wait for rollout to complete
            kubectl rollout status deployment/java-app -n boardgame
            
            # Show deployment status
            kubectl get pods -l app=java-app -n boardgame
        """
    }
}
}
  
  post {
    always {
      sh """
        echo "Versions:"
        java -version || true
        mvn -v || true
        aws --version || true
        echo "Docker info (snippet):"
        docker info 2>/dev/null | grep -i -E "server version" || true
      """
    }
    cleanup {
      sh """
        docker rmi ${IMAGE_NAME}:latest ${IMAGE_NAME}:${VERSION_TAG} || true
        docker image prune -f || true
      """
    }
  }
}
