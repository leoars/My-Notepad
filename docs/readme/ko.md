# My Notepad

[Português (Brasil)](../../README.md) · [English](en.md) · [Español](es.md) · [Français](fr.md) · [Deutsch](de.md) · [Italiano](it.md) · [日本語](ja.md) · **한국어**

Windows 7 메모장에서 영감을 받은 macOS용 일반 텍스트 편집기입니다. .txt 파일을 열고 몇 줄 적은 다음 익숙한 단축키로 저장하세요.

## macOS용 다운로드

- **[Apple Silicon(M 시리즈)용 다운로드](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-arm64.pkg)**
- **[Intel용 다운로드](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-x86_64.pkg)**

macOS 12 이상이 필요합니다. [최신 릴리스 보기](https://github.com/leoars/My-Notepad/releases/latest)

![현장 노트를 연 편집기. ‘다리’가 선택되어 있고 창 아래에 커서의 줄과 열이 표시됩니다.](../screenshots/ko-editor.png)

## 만든 이유

Windows에서 Mac으로 옮기고 나니 주소를 적거나 오래된 파일의 한 줄을 고칠 때 쓰던 작은 메모장 창이 그리웠습니다. My Notepad는 Swift와 AppKit으로 그 작업 방식을 되살린 프로젝트입니다. 창 하나에 문서 하나와 메뉴 다섯 개가 있습니다. 글꼴은 편집기 설정으로 기억하고, 파일에는 텍스트만 저장합니다.

## 일상적인 편집

- 찾기 창을 열어 둔 채 본문을 검색하거나 바꿀 수 있습니다. 자동 줄 바꿈을 끄면 **편집 → 이동…** 으로 원하는 줄에 바로 갈 수 있습니다. **보기 → 상태 표시줄** 을 켜면 현재 줄과 열이 표시됩니다.
- Windows-1252, UTF-8, UTF-16(LE 및 BE) 파일을 열 수 있으며 Windows, Mac, Unix의 줄바꿈 형식을 지원합니다. 선택한 인코딩으로 표현할 수 없는 문자가 있으면 UTF-8로 저장할 수 있습니다.
- **서식** 메뉴에서 글꼴을 선택하거나 **Ctrl** 키를 누른 채 마우스 휠을 돌려 글자 크기를 조절하세요. 인쇄할 때 여백과 머리글, 바닥글을 지정할 수 있습니다.

![‘다리’를 ‘보행교’로 변경하도록 설정한 바꾸기 창.](../screenshots/ko-replace.png)

### 키보드 단축키

| 키 | 동작 |
| --- | --- |
| `Ctrl+F` · `F3` | 텍스트 찾기 및 다음 항목으로 이동 |
| `Ctrl+H` | 바꾸기 창 열기 |
| `Ctrl+G` | 원하는 줄로 이동 |
| `Ctrl+Shift+←` / `→` | 단어 단위로 선택 영역 늘리기 또는 줄이기 |
| `Ctrl++` / `Ctrl+-` | 글자 크기 키우기 또는 줄이기 |
| `F5` | 현재 시간과 날짜 삽입 |

### 텍스트 파일로 작업 일지 쓰기

파일 첫 줄에 `.LOG`를 입력한 다음 저장하고 다시 열어 보세요. 파일 끝에 현재 시간과 날짜가 추가됩니다. 이어서 기록을 작성한 뒤 저장하면 일지에 남습니다.

## Mac에서 빌드 및 설치

설치 패키지는 macOS 12 이상을 실행하는 Apple Silicon 및 Intel Mac용입니다. 직접 빌드하려면 Swift 컴파일러가 포함된 Apple 개발 도구와 Python 3가 필요합니다. 프로젝트 루트에서 다음 명령을 실행하세요.

```sh
./build.sh
open "My Notepad.app"
```

아래 명령으로 두 아키텍처용 설치 패키지를 모두 만듭니다. `dist/`에서 Apple Silicon용 `arm64` 또는 Intel용 `x86_64` 패키지를 선택하세요. `.pkg` 파일을 열면 앱을 `/Applications`에 설치할 수 있습니다.

```sh
./package.sh
```

## 기여하기

[편집기, 메뉴, 파일 입출력](../../Sources)은 Swift로 구현했습니다. [번역 파일](../../Resources)은 언어별 `.lproj` 폴더에 있습니다. 키보드나 인코딩 문제를 제보할 때는 macOS 버전, 키보드 배열 또는 파일 인코딩, 문제를 재현할 수 있는 짧은 예를 함께 알려 주세요.

## 라이선스

프로젝트에서 작성한 코드와 문서에는 [Apache License 2.0](../../LICENSE)이 적용됩니다.
