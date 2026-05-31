pipeline{
    agent any // 어떤 에이전트(실행 서버)에서든 실행 가능

    tools {
        maven 'maven 3.9.12' // Jenkins에 등록된 Maven 3.9.12를 사용, jenkins에 등록한 이름과 꼭 동일해야함!
    }

    environment {
        // 배포에 필요한 변수 설정
        DOCKER_IMAGE = "demo-app" // 도커 이미지 이름
        CONTAINER_NAME = "springboot-container" // 도커 컨테이너 이름
        JAR_FILE_NAME = "app.jar" // 복사할 JAR 파일 이름
        PORT = "8081" // 컨테이너에 연결한 포트

        REMOTE_USER = "ec2-user" // 원격(spring) 서버 사용자
        REMOTE_HOST = "13.125.179.192" // 원격(spring) 서버 IP(Public IP), aws에서 제공하는 public ip

        REMOTE_DIR = "/home/ec2-user/deploy" // 원격 서버에 파일 복사할 경로
        SSH_CREDENTIALS_ID = "2d5141c7-3471-46c8-bf79-6fcc64afe22f" // Jenkins SSH 자격 증명 ID

        // Jenkins Secret File ID
        //SECRET_FILE_ID = "bd268dcd-4965-4df0-bb8e-97ae3c68b8a0"
    }

    stages{
        stage('Git Checkout'){
            steps { // steps : stage 안에서 실행할 실제 명령어
                // Jenkins에 연결된 Git 저장소에서 최신 코드 체크 아웃
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                // 테스트는 건너뛰고 Maven 빌드 수행
                sh 'mvn clean package -DskipTests'
                // sh '' : 리눅스 명령어 실행
            }
        }

        stage('Prepare Jar'){
            steps {
                // 빌드 결과물인 JAR 파일을 지정한 이름(app.jar)으로 복사
                sh 'cp target/demo-0.0.1-SNAPSHOT.jar ${JAR_FILE_NAME}'
            }
        }

        // .properties 파일의 GIT IGNORE 등의 설정도 진행해야하긴 함
        /*
        stage('Inject Spring Config (Secret File)') {
            steps {
                withCredentials([file(credentialsId: env.SECRET_FILE_ID, variable: 'SPRING_CONFIG_FILE')]) {
                    sh """
                        echo "[INFO] Using secret file: $SPRING_CONFIG_FILE"
                        cp \$SPRING_CONFIG_FILE ./application-prod.properties
                    """
                }
            }
        }
        */

        stage('Copy to Remote Server'){
            steps {
                // jenkins가 원격 서버에 ssh 접속할 수 있도록 sshagent(플러그인 깔았던 것) 사용
                sshagent (credentials : [env.SSH_CREDENTIALS_ID]) { // 교환된 키로 확인 하겠다라는 의미, 젠킨스에 있는 SSH_CREDENTIALS_ID 를 불러온다.
                    // 원격 서버에 배포 디렉토리 생성 (없으면 새로 만듦)
                    // 서버끼리 키 공유했으니까 StrictHostKeyChecking=no 로 설정..
                    sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} \"mkdir -p ${REMOTE_DIR}\""
                    // JAR 파일과 Dockerfile을 원격 서버에 복사
                    sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${JAR_FILE_NAME} Dockerfile ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
                }
            }
        }

        stage('Remote Docker Build & Deploy'){
            steps {
                sshagent (credentials : [env.SSH_CREDENTIALS_ID]) {
                    // app.jar랑 dockerfile을 보내고 REMOTE_USER@REMOTE_HOST 들어가서 실행하겠다
                    // cd REMOTE_DIR 하고 이미지가 계속 업데이트 되므로 기존 컨테이너 삭제(rm)하고 실행하기
                    sh """
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
    cd ${REMOTE_DIR} || exit 1
    docker rm -f ${CONTAINER_NAME} || true
    docker build -t ${DOCKER_IMAGE} .
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${DOCKER_IMAGE}
ENDSSH
                    """
                }
            }
        }
    }
}