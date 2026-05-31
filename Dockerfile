# jdk 17 도커 이미지를 다운로드
FROM eclipse-temurin:17-jdk

# JAR 파일이 저장될 작업 디렉토리 설정
WORKDIR /app

# Maven 또는 Gradle 빌드 후 생성된 jar 파일을 컨테이너 내부 /app 디렉토리에 app.jar 이름으로 복사
# (나중에 demo.snapshot을 app으로 바꿔서 빌드할것임..)
COPY app.jar app.jar

# 실행 포트 지정
EXPOSE 8081

# 컨테이너 실행 시 JAR 실행
ENTRYPOINT ["java", "-jar", "app.jar"]