pipeline {

  agent {label 'debian-10' }

  environment {
    DOCKER_REG = '[DOCKER_HOST].com'
    NEXUS_REG = 'nexus-jenkins'
    SERVICE = 'batman'
    TILLER_NAMESPACE = "batman-tiller"
  }

  stages {

    stage("docker") {
      steps {
        container('worker') {
          script {
            docker.withRegistry('https://$DOCKER_REG', 'NEXUS_REG') {
              sh '''#!/bin/bash -xe
                docker build -t $DOCKER_REG/$SERVICE:${GIT_COMMIT:0:8} .
                SUCCESS=$?
                if [[ $SUCCESS -ne 0 ]]; then
                  exit 1
                fi
                echo "Successfully build the batman image"
                echo "Push batman container image to nexus"
                docker push $DOCKER_REG/$SERVICE:${GIT_COMMIT:0:8}

                docker tag $DOCKER_REG/$SERVICE:${GIT_COMMIT:0:8} $DOCKER_REG/$SERVICE:latest
                docker push $DOCKER_REG/$SERVICE:latest

                SUCCESS=$?
                if [[ $SUCCESS -ne 0 ]]; then
                  exit 1
                fi
                echo "Pushed docker image for $SERVICE with ${GIT_COMMIT:0:8} to Nexus"

                cd ./resources/update-manager/
                docker build -t $DOCKER_REG/update-manager:${GIT_COMMIT:0:8} .
                SUCCESS=$?
                if [[ $SUCCESS -ne 0 ]]; then
                  exit 1
                fi
                echo "Successfully build the update-manager image"
                echo "Push update-manager container image to nexus"
                docker push $DOCKER_REG/update-manager:${GIT_COMMIT:0:8}

                docker tag $DOCKER_REG/update-manager:${GIT_COMMIT:0:8} $DOCKER_REG/update-manager:latest
                docker push $DOCKER_REG/update-manager:latest

                SUCCESS=$?
                if [[ $SUCCESS -ne 0 ]]; then
                  exit 1
                fi
                echo "Pushed docker image for $SERVICE with ${GIT_COMMIT:0:8} to Nexus"

              '''
            }
          }
        }
      }
    }

    stage("nondprod-deploy") {
      when { not { branch 'master' } }
      steps {
        container('worker') {
          withKubeConfig( credentialsId: "cluster--service-account" ) {
            script {
                sh '''#!/bin/bash -xe
                  helm init --client-only
                  helm dependency update resources/chart/
                  helm upgrade \
                    -i \
                    batman-test \
                    ./resources/chart \
                    --set image.tag=${GIT_COMMIT:0:8} \
                    -f ./resources/deployment/test.yaml \
                    --namespace batman \
                    --tiller-namespace $TILLER_NAMESPACE \
                    --force \
                    --wait
                '''
            }
          }
        }
      }
    }

    stage("prod-deploy") {
      when { branch 'master' }
      steps {
        container('worker') {
          withKubeConfig( credentialsId: "cluster--service-account" ) {
            script {
              sh '''#!/bin/bash -xe
                helm init --client-only
                helm dependency update resources/chart/
                helm upgrade \
                  -i \
                  batman-prod \
                  ./resources/chart \
                  --set image.tag=${GIT_COMMIT:0:8} \
                  -f ./resources/deployment/prod.yaml \
                  --namespace batman \
                  --tiller-namespace $TILLER_NAMESPACE \
                  --force \
                  --wait
              '''
          }
        }
      }
    }
  }

  }
}
