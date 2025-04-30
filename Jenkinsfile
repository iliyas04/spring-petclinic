pipeline {
    agent any
    
    tools {
        // Define tools with the names you set in Global Tool Configuration
        terraform 'ttff'  // This uses the tool with the name 'terraform'
        ansible 'aann'      // This uses the tool with the name 'ansible'
        maven 'mmvvnn'      // This uses the tool with the name 'maven'
    }
    environment {
        AWS_ACCESS_KEY = credentials('AWS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET')
        SSH_PRIVATE_KEY_PATH = "~/.ssh/mujahed.pem"  // Path to your private key
    }
    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'master', url: 'https://github.com/NubeEra-ImranAli/spring-boot-war-example.git'
            }
        }

        stage('Setup Terraform') {
            steps {
                script {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }
     stage('Provision Infrastructure with Terraform') {
            steps {
                sh '''
                    terraform init
                    terraform apply -auto-approve
                '''
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                script {
                    def tomcatIp = sh(script: "terraform output -raw tomcat_server_ip", returnStdout: true).trim()
                    def mysqlIp = sh(script: "terraform output -raw mysql_server_ip", returnStdout: true).trim()
                    def mavenIp = sh(script: "terraform output -raw maven_server_ip", returnStdout: true).trim()

                    writeFile file: 'inventory', text: """
                    [tomcat]
                    ${tomcatIp} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

                    [mysql]
                    ${mysqlIp} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

                    [maven]
                    ${mavenIp} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
                    """
                }
            }
        }

        stage('Verify SSH Connectivity') {
            steps {
                sh '''
                    ansible -i inventory all -m ping
                '''
            }
        }

        stage('Install Tomcat, MySQL, Maven') {
            steps {
                sh '''
                    ansible-playbook -i inventory ansible/setup-all.yml
                '''
            }
        }

        stage('Build Java App on Maven Server') {
            steps {
                sh '''
                    ansible-playbook -i inventory ansible/build-on-maven.yml
                '''
            }
        }

        stage('Deploy WAR to Tomcat') {
            steps {
                sh '''
                    ansible-playbook -i inventory ansible/deploy-to-tomcat.yml
                '''
            }
        }
    }

    post {
        success {
            echo "✅ All systems provisioned and app deployed!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    } 
}  











