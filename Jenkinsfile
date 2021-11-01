pipeline {
    agent any
    parameters {
        string(name: 'Environment', defaultValue: 'dev', description: 'Environemnt')
    }
    stages {
        stage('Validate') {
            steps {
                sh "terraform validate"
            }
        }
        stage('Plan') {
            steps {
                sh """ terraform plan --var-file ${params.Environment}.tfvars """
            }
        }
    }
}