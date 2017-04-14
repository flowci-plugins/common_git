 # ************************************************************
#
# This step will clone your project code from git
#
#   Variables used:
#     $FLOW_GIT_EVENT_TYPE
#     $FLOW_GIT_BRANCH
#     $FLOW_PROJECT_GIT_URL
#     $FLOW_PROJECT_NAME
#     $FLOW_GIT_CURRENT_BRANCH
#     $FLOW_GIT_SPECIFIED_COMMIT
#     $FLOW_GIT_TARGET_BRANCH
#     $FLOW_GIT_CURRENT_SSH_URL
#
#   Outputs:
#     $FLOW_GIT_BRANCH
#     $FLOW_GIT_SPECIFIED_COMMIT
#     $FLOW_PROJECT_GIT_URL
#     $FLOW_CURRENT_PROJECT_PATH
#
# ************************************************************

cd ${FLOW_WORKSPACE}/build
getFlowProjectPath(){
    case $FLOW_PROJECT_LANGUAGE in
        android)
        filename="gradlew"
        ;;
        objc)
        filename="*.xcodeproj"
        ;;
        java)
        filename="pom.xml"
        ;;
        ruby)
        filename="Gemfile"
        ;;
        php)
        filename="composer.json"
        ;;
        python)
        filename="requirements.txt"
        ;;
        nodejs)
        filename="package.json"
        ;;
        *)
        echo "can not determine the language "
        ;;
    esac
    total=$(find . -name $filename -type f -maxdepth 2)
    if [ -z "$total" ] ; then
        echo "No $filename Found"
    else
        #判断根目录是否有pom.xml文件
        fileInRoot=$(find . -name $filename -type f -maxdepth 1)
        if [ -z "$fileInRoot" ] ; then 
        echo "No $filename Found at root,we find $filename in submodule and we will build the first submodule"
        dirOfFile=$(find . -name "pom.xml" -type f -maxdepth 2  | awk -F './' 'NR==1 { print substr($0,3)}')
        FLOW_PROJECT_PATH=${dirOfFile%/*}
        fi
    fi

}
export PKEY=${FLOW_WORKSPACE}/.ssh/id_rsa
export GIT_SSH=${FLOW_WORKSPACE}/.ssh/ssh-git.sh
export FLOW_CURRENT_PROJECT_PATH=$FLOW_WORKSPACE/build/$FLOW_PROJECT_NAME/$FLOW_PROJECT_PATH

if [[ $FLOW_GIT_EVENT_TYPE == "push" ]]; then
  flow_cmd "git clone --depth=50 --branch=$FLOW_GIT_BRANCH $FLOW_PROJECT_GIT_URL $FLOW_PROJECT_NAME" --echo --assert
  cd $FLOW_PROJECT_NAME
fi

if [[ $FLOW_GIT_EVENT_TYPE == "manual" ]]; then
  flow_cmd "git clone --depth=50 --branch=$FLOW_GIT_BRANCH $FLOW_PROJECT_GIT_URL $FLOW_PROJECT_NAME" --echo --assert
  cd $FLOW_PROJECT_NAME
  FLOW_GIT_SPECIFIED_COMMIT="$(git rev-parse HEAD)"
fi

if [[ $FLOW_GIT_EVENT_TYPE == "timer" ]]; then
  flow_cmd "git clone --depth=50 --branch=$FLOW_GIT_BRANCH $FLOW_PROJECT_GIT_URL $FLOW_PROJECT_NAME" --echo --assert
  cd $FLOW_PROJECT_NAME
fi


if [[ $FLOW_GIT_EVENT_TYPE == "tag" ]]; then
  flow_cmd "git clone --depth=50  $FLOW_PROJECT_GIT_URL $FLOW_PROJECT_NAME" --echo --assert
  cd $FLOW_PROJECT_NAME
  flow_cmd "git fetch --tags" --echo --assert
  flow_cmd "git checkout $FLOW_GIT_TAG" --echo --assert
fi

if [[ $FLOW_GIT_EVENT_TYPE == "pull_request" ]]; then

echo "
# ********************************************************************************************
# Git 若提示 Please make sure you have the correct access rights and the repository exists
# 原因：
#     没权限拉取PR的代码
# 解决方案：
#     请保证PR关联的项目都在flow.ci上创建
# ********************************************************************************************
"

  flow_cmd "git clone --depth=50 --branch=$FLOW_GIT_TARGET_BRANCH $FLOW_PROJECT_GIT_URL $FLOW_PROJECT_NAME" --echo --assert
  cd $FLOW_PROJECT_NAME
  unset "SSH_AUTH_SOCK"
  unset "SSH_AGENT_PID"
  export PKEY=${FLOW_WORKSPACE}/.ssh/id_rsa_target
  flow_cmd "git fetch $FLOW_GIT_CURRENT_SSH_URL $FLOW_GIT_CURRENT_BRANCH" --echo --assert
  flow_cmd "git merge --no-edit FETCH_HEAD" --echo --assert
fi

if [ -z $FLOW_GIT_SPECIFIED_COMMIT ]; then
  echo
else
  flow_cmd "git checkout $FLOW_GIT_SPECIFIED_COMMIT" --echo --assert
fi
echo $FLOW_CURRENT_PROJECT_PATH
getFlowProjectPath
FLOW_CURRENT_PROJECT_PATH+="$FLOW_PROJECT_PATH"
echo $FLOW_CURRENT_PROJECT_PATH
echo "cd $FLOW_CURRENT_PROJECT_PATH"
