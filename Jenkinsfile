pipeline {
  agent { label 'jenkins-slave' }
  stages {
    stage('Build and push to Dockerhub') {
      steps {
        script {
        withCredentials([usernamePassword(credentialsId: 'Dockerhub-credentials :)', passwordVariable: 'dockerhub-password ', usernameVariable: 'dockerhub-user')]) {
          sh """
              docker login -u ${dockerhub-user} -p ${dockerhub-password}
              cd docker
              docker build -t ahmedemad111/graduation-project:2 .
              docker push ahmedemad111/graduation-project:2
          """
        }
        
      }
      }
      
    }
    stage('Deploy our application') {
      steps {
       script {

          sh """
              gcloud container clusters get-credentials final-gke-cluster --region europe-west3 --project ahmed-emad-project
              cd kubernetes
              kubectl apply -f docker-deployment-with-service.yaml -n ahmed-jenkins
          """
        
        
      }
      }
    }
  }
}
