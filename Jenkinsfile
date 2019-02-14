pipeline {
  agent {
    node {
      label 'BodhiAgent'
    }

  }
  stages {
    stage('1st stage') {
      steps {
        sh '''ls /home/asusendless
[ -f /etc/passwd ]
'''
      }
    }
    stage('second stage') {
      steps {
        echo '2nd stage'
        sh 'echo -e ${SEAN}'
      }
    }
  }
  environment {
    SEAN = 'OH HELLO THERE!'
  }
}