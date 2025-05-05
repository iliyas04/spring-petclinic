pipeline {
    agent any
    
    tools {
        // Define tools with the names you set in Global Tool Configuration
        terraform 'terra'  // This uses the tool with the name 'terraform'
        ansible 'ansible'      // This uses the tool with the name 'ansible'
        maven 'maven'      // This uses the tool with the name 'maven'
    }
    environment {
        AWS_ACCESS_KEY = credentials('AWS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET')
        SSH_PRIVATE_KEY_PATH = "~/.ssh/mujahed.pem"  // Path to your private key
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'master', url: 'https://github.com/patanfouziya/spring-petclinic.git'
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
        
         stage('Generate Inventory') {
            steps {
                script {
                    // Generate the inventory for all servers (build_server, tomcat_server, artifact_server)
                    sh """
                     echo "[tomcat_server]" > inventory
                     echo "\$(terraform output -raw tomcat_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory
                      
                     echo "[mysql_server]" > inventory
                     echo "\$(terraform output -raw mysql_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory


                     echo "[maven_server]" > inventory
                     echo "\$(terraform output -raw maven_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory
                    """
                }
            }
         }

          stage('Verify Ansible Connectivity') {
            steps {
                script {
                    // Get the IP addresses of the EC2 instances created by Terraform
                    def tomcatServerIp = sh(script: "terraform output -raw tomcat_server_ip", returnStdout: true).trim()
                    def mysqlServerIp = sh(script: "terraform output -raw mysql_server_ip", returnStdout: true).trim()
                    def mavenServerIp = sh(script: "terraform output -raw maven_server_ip", returnStdout: true).trim()
                 
                    // Define the servers and their IPs in a map
                    def servers = [
                        "tomcat_server": tomcatServerIp,
                        "mysql_server" : mysqlServerIp,
                        "maven_server" : mavenServerIp
                    ]
               
                     // SSH user and private key path
                    def sshUser = "ubuntu"  // Replace with your SSH user if it's different
                    def sshPrivateKey = "${SSH_PRIVATE_KEY_PATH}"  // Use the path to your private key
        
                    // Check if all servers are up and reachable via SSH
                    def retries = 0
                    def maxRetries = 30  // Maximum number of retries (e.g., 30 attempts)
                    def waitTime = 10    // Wait time between retries (in seconds)
        
                    def reachableServers = [:]
                    servers.each { serverName, ip ->
                        reachableServers[serverName] = false
                    }
                    
                    while (reachableServers.containsValue(false) && retries < maxRetries) {
                        servers.each { serverName, ip ->
                            if (!reachableServers[serverName]) {
                                // Try to SSH into the EC2 instance
                                def result = sh(script: """
                                    ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i ${sshPrivateKey} ${sshUser}@${ip} 'echo SSH connected'
                                """, returnStatus: true)
        
                                if (result == 0) {
                                    echo "${serverName} (${ip}) is reachable via SSH."
                                    reachableServers[serverName] = true
                                } else {
                                    echo "${serverName} (${ip}) is not reachable via SSH yet. Retrying."
                                }
                            }
                        }

                         if (reachableServers.containsValue(false)) {
                            retries++
                            echo "Attempt ${retries}/${maxRetries} failed. Waiting for all servers to be reachable via SSH."
                            sleep(waitTime)
                        }
                    }

                     if (reachableServers.containsValue(false)) {
                        error "Some EC2 instances are not reachable via SSH after ${maxRetries} attempts."
                    }


                     // Once all instances are reachable, run the Ansible ping
                    echo "All servers are reachable via SSH. Running Ansible Ping..."
                    sh """
                    ansible -i inventory all -m ping
                    """
                }
            }
        }

                stage('Run Ansible Setup') {
            steps {
                sh """
                    ansible-playbook -i inventory setup.yml
                """
            }
        }
    
        stage('Build WAR File with Maven') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('Copy WAR File to Artifact Server') {
            steps {
                script {
                    def artifactServerIp = sh(script: "terraform output -raw maven_server_ip", returnStdout: true).trim()
                    sh """
                    scp -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no target/*.war ubuntu@${artifactServerIp}:/home/ubuntu/app.war
                    """
                }
            }
        }

        stage('Deploy WAR to Tomcat via Ansible') {
            steps {
                sh "ansible-playbook -i inventory deploy.yml"
            }
        }
    }

    post {
        failure {
            echo "Build or deployment failed."
        }
        success {
            echo "Application deployed successfully."
        }
    }
}











