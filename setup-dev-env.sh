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
echo -e "${GREEN}pyenv와 poetry 설치 스크립트${NC}"
echo -e "${BLUE}====================================================${NC}"

# OS 확인
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}macOS가 감지되었습니다.${NC}"
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${YELLOW}Linux가 감지되었습니다.${NC}"
    OS_TYPE="linux"
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
    brew install curl git
elif [[ "$OS_TYPE" == "linux" ]]; then
    sudo apt-get update
    sudo apt-get install -y curl git python3 python3-pip
fi

# 쉘 설정 추가
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

# 완료 메시지
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}개발 환경 설정이 완료되었습니다!${NC}"
echo -e "${YELLOW}pyenv 버전: $(pyenv --version)${NC}"
echo -e "${YELLOW}Poetry 버전: $(poetry --version)${NC}"
echo -e "${BLUE}====================================================${NC}"
