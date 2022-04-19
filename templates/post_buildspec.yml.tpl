version: 0.2

env:
  parameter-store:
    USER: "/app/bb_user"  
    PASS: "/app/bb_app_pass"
    RELEASE_HOOK_URL: "/app/jira_release_hook"

phases:
  pre_build:
    commands:
      - echo "about to shift traffic"
  build:
    commands:
      - | 
        aws s3 mv s3://${BUCKET}/pre-release/ s3://${BUCKET}/ --recursive
        aws s3 rm s3://${BUCKET}/pre-release/
      - aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/**/*" "/*"
  post_build:
    commands:
      - |
        REPORT_URL="https://us-east-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/codepipeline-${APP_NAME}-${ENV_NAME}"
        URL="https://api.bitbucket.org/2.0/repositories/${REPO_NAME}/commit/$COMMIT_ID/statuses/build/"
        curl --request POST --url $URL -u "$USER:$PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"key\":\"${APP_NAME} Deploy\",\"state\":\"SUCCESSFUL\",\"description\":\"Deployment to ${ENV_NAME} succeeded\",\"url\":\"$REPORT_URL\"}"    
      - |
        if [ "${ENV_NAME}" == "prod" ]; then 
          export RELEASE_VERSION="1.1.1"
          curl --request POST --url $RELEASE_HOOK_URL --header "Content-Type:application/json" --data "{\"data\": {\"releaseVersion\":\"$RELEASE_VERSION\"}}" || echo "No Jira to change"
        fi
