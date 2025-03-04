#!/bin/bash

set -e

# 현재 쉘 확인
CURRENT_SHELL=$(basename "$SHELL")

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}pyenv, poetry, Docker 설치 스크립트${NC}"
echo -e "${BLUE}====================================================${NC}"

# OS 확인
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}macOS가 감지되었습니다.${NC}"
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${YELLOW}Linux가 감지되었습니다.${NC}"
    
    # WSL 확인
    if grep -q Microsoft /proc/version; then
        echo -e "${YELLOW}Windows Subsystem for Linux (WSL)이 감지되었습니다.${NC}"
        OS_TYPE="wsl"
    else
        OS_TYPE="linux"
    fi
else
    echo -e "${YELLOW}지원되지 않는 OS입니다. 이 스크립트는 macOS와 Linux에서만 실행됩니다.${NC}"
    exit 1
fi

# 필요한 패키지 설치
echo -e "\n${GREEN}필요한 패키지를 설치합니다...${NC}"
if [[ "$OS_TYPE" == "macos" ]]; then
    # Homebrew가 설치되어 있는지 확인
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Homebrew가 설치되어 있지 않습니다. 설치를 진행합니다...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    brew install curl git docker

    # macOS용 Python 의존성 패키지 설치
    echo -e "\n${GREEN}macOS용 Python 빌드 의존성 패키지를 설치합니다...${NC}"
    brew install openssl readline sqlite3 xz zlib tcl-tk
elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
    sudo apt-get update
    sudo apt-get install -y curl git python3 python3-pip apt-transport-https ca-certificates gnupg lsb-release

    # Linux/WSL용 Python 빌드 의존성 패키지 설치
    echo -e "\n${GREEN}Linux/WSL용 Python 빌드 의존성 패키지를 설치합니다...${NC}"
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    # Ubuntu 특정 배포판 확인 (SSL 관련 추가 패키지)
    if [[ -f /etc/lsb-release ]]; then
        DISTRIB_ID=$(grep DISTRIB_ID /etc/lsb-release | cut -d= -f2)
        DISTRIB_RELEASE=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d= -f2)

        if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
            echo -e "\n${GREEN}Ubuntu ${DISTRIB_RELEASE}를 위한 추가 패키지를 설치합니다...${NC}"
            # Ubuntu 22.04+ 용 추가 패키지
            if [[ $(echo "$DISTRIB_RELEASE >= 22.04" | bc) -eq 1 ]]; then
                sudo apt-get install -y libgdbm-compat-dev uuid-dev
            fi
        fi
    fi

    # Docker 설치 (Linux의 경우)
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Docker GPG 키 추가
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Docker 리포지토리 설정
        echo \
          "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Docker 엔진 설치
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [[ "$OS_TYPE" == "wsl" ]]; then
        echo -e "\n${GREEN}WSL용 Docker 설치를 준비합니다...${NC}"

        # Docker Desktop for Windows에서 WSL로 접근하는 경우
        echo -e "${YELLOW}WSL에서는 Docker Desktop for Windows를 사용하는 것을 권장합니다.${NC}"
        echo -e "${YELLOW}먼저 Windows에 Docker Desktop을 설치하고, WSL 통합을 활성화해주세요.${NC}"

        # Docker CLI 설치
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose
    fi
fi

# pyenv 설치
echo -e "\n${GREEN}pyenv를 설치합니다...${NC}"
if ! command -v pyenv &> /dev/null; then
    curl https://pyenv.run | bash

    # 쉘 설정 업데이트
    echo -e "\n${YELLOW}쉘 설정을 업데이트합니다. 환경 변수를 설정합니다...${NC}"

    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        source ~/.bashrc
    elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
        echo 'eval "$(pyenv init -)"' >> ~/.zshrc
        source ~/.zshrc
    else
        echo -e "${YELLOW}지원되지 않는 쉘입니다. 수동으로 환경 변수를 설정해주세요.${NC}"
    fi
else
    echo -e "${YELLOW}pyenv가 이미 설치되어 있습니다.${NC}"
fi

# Poetry 설치
echo -e "\n${GREEN}Poetry를 설치합니다...${NC}"
if ! command -v poetry &> /dev/null; then
    curl -sSL https://install.python-poetry.org | python3 -

    # 쉘 설정 추가
    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi

    # Poetry 설정
    poetry config virtualenvs.in-project true
else
    echo -e "${YELLOW}Poetry가 이미 설치되어 있습니다. 최신 버전으로 업데이트합니다...${NC}"
    poetry self update
fi

# Docker 권한 설정 (Linux의 경우)
if [[ "$OS_TYPE" == "linux" ]]; then
    echo -e "\n${GREEN}Docker 권한을 설정합니다...${NC}"
    sudo usermod -aG docker $USER

    echo -e "\n${YELLOW}Docker 그룹에 사용자를 추가했습니다.${NC}"
    echo -e "${YELLOW}변경사항을 적용하려면 로그아웃 후 다시 로그인해주세요.${NC}"
fi

# WSL의 경우 추가 가이드
if [[ "$OS_TYPE" == "wsl" ]]; then
    echo -e "\n${YELLOW}WSL에서 Docker 사용 시 주의사항:${NC}"
    echo -e "1. ${BLUE}Windows의 Docker Desktop에서 WSL 통합 옵션을 반드시 활성화해주세요.${NC}"
    echo -e "2. ${BLUE}Windows PowerShell 또는 명령 프롬프트에서 다음 명령어를 실행해주세요:${NC}"
    echo -e "   ${GREEN}wsl --update${NC}"
    echo -e "3. ${BLUE}Docker Desktop의 WSL 통합 설정에서 현재 WSL 배포판을 선택해주세요.${NC}"
fi

# 완료 메시지
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}개발 환경 설정이 완료되었습니다!${NC}"
echo -e "${YELLOW}pyenv 버전: $(pyenv --version)${NC}"
echo -e "${YELLOW}Poetry 버전: $(poetry --version)${NC}"
echo -e "${YELLOW}Docker 버전: $(docker --version)${NC}"
echo -e "${BLUE}====================================================${NC}"
