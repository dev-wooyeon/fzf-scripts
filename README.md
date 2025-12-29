# fzf-scripts

fzf를 중심으로 한 **개발자 업무 자동화 스크립트 모음**입니다.  
로컬에 흩어진 저장소, 로그, 설정, 문서 작업을  
**검색 → 판단 → 실행**의 흐름으로 빠르게 처리하는 것을 목표로 합니다.

이 저장소의 스크립트들은  
단순 실행 스크립트가 아니라,  
사람의 판단이 필요한 작업을 fzf UI로 끌어올린 **Developer Productivity Tool**입니다.

## 핵심 컨셉

- **fzf를 이용한 인터랙티브 선택** – 리스트에서 원하는 항목을 빠르게 선택할 수 있습니다.  
- **codex CLI를 이용한 문서 및 코드 자동 생성** – 반복적인 README 정리, 코드 스켈레톤 생성 등을 자동화합니다.  
- **repo 단위, 작업 단위로 독립적인 실행** – 각각의 저장소나 작업은 다른 작업에 영향 없이 처리합니다.  
- **사람이 최종 판단을 내리는 반자동 워크플로우** – 자동화가 결과를 제시하지만 최종 결정은 사람이 내립니다.

자동화는 빠르지만  
결과에 대한 책임은 사람이 지는 구조를 지향합니다.

## 주요 사용 사례

- 여러 Git Repository 중 README 정리가 필요한 저장소만 선별
- 표준 템플릿 기반 README 자동 생성
- Codex 실행 로그를 repo 단위로 관리
- 반복되는 로컬 작업을 fzf 기반 명령으로 통합

## 디렉터리 구조

fzf-scripts/
readme-template.md
scripts/
generate-readme.sh
.codex/
README.prompt.md
README.codex.log

각 스크립트는  
하나의 문제를 하나의 책임으로 해결하도록 분리되어 있습니다.

## 요구 사항

### 필수 도구

- macOS 또는 Linux
- bash 4 이상
- fzf

### 선택 도구

- **codex CLI** – README 자동 생성 및 코드 보조 작업에 사용합니다.

## 설치

### fzf 설치 (macOS 예시)

```bash
brew install fzf

설치 후 shell integration을 권장합니다.

$(brew --prefix)/opt/fzf/install
```

### codex CLI 설치

codex CLI는 OpenAI Codex 기반 CLI 도구입니다.
설치 및 인증은 공식 문서를 따르세요. 설치 후 다음 명령으로 정상 설치를 확인합니다.
```bash
codex --version
```
### 권한 설정

스크립트는 실행 권한이 필요합니다.
```bash
chmod +x scripts/*.sh

자주 사용하는 경우 PATH를 등록해 두는 것이 편리합니다.
export PATH="$PATH:/path/to/fzf-scripts/scripts"
```


## 사용 방법

### README 자동 생성 스크립트

기본 실행:
``` bash
generate-readme.sh
```
workspace를 직접 지정하려면:
``` bash
generate-readme.sh ~/workspace
```

### 실행 흐름
1.	workspace 하위 git repository 자동 탐색
2.	fzf UI로 다중 repository 선택
3.	선택된 repo의 README 미리보기 표시
4.	README 생성용 Codex prompt 자동 생성
5.	Codex 실행 여부 결정
6.	결과 README.md 생성 및 로그 저장

이 과정을 통해 README를 다시 써야 할지, 이미 충분한지를 실행 전에 판단할 수 있습니다.


### fzf Preview에서 확인 가능한 정보
	•	Repository 경로
	•	기존 README.md 상단 내용
	•	Git 브랜치 및 변경 상태
	•	README 재작성 필요 여부


## Codex 실행 결과

Codex는 repo 단위로 실행되며 다음과 같은 파일들이 자동 생성됩니다.
```text
.codex/
  README.prompt.md
  README.codex.log
```

README.prompt.md
	•	Codex 입력 프롬프트
	•	Repository 상태와 템플릿 정보 포함

README.codex.log
	•	Codex 실행 로그
	•	실패 원인 추적 및 재실행에 사용

Codex 자동 실행을 제어하려면 환경 변수를 설정하세요:
``` bash
AUTO_RUN_CODEX=0 generate-readme.sh
```
이 경우 prompt 파일만 생성되고 Codex 실행은 수동으로 진행합니다.


### 병렬 실행 (선택)

repo 수가 많을 경우 xargs나 GNU parallel을 사용해 병렬 실행할 수 있습니다.
Codex는 CPU 사용량이 크므로 동시 실행은 2~4개 정도를 권장합니다.
