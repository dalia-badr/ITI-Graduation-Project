pipeline {
  agent { label 'slave' }
  stages {
    stage('Build and push to Dockerhub') {
      steps {
        script {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'dockerpassword', usernameVariable: 'dockeruser')]) {
          sh """
              docker login -u ${dockeruser} -p ${dockerpassword}
              cd docker
              docker build -t daliabadr/dalia-graduation-project .
              docker push daliabadr/dalia-graduation-project
          """
        }
        
      }
      }
      
    }
    stage('Deploy our application') {
      steps {
       script {

          sh """
              gcloud container clusters get-credentials final-gke-cluster --region europe-west3 --project starry-compiler-344415
              cd kubernetes
              kubectl apply -f docker-deployment-with-service.yaml -n ahmed-jenkins
          """
        
        
      }
      }
    }
  }
}




