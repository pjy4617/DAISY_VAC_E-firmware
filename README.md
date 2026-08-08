# DAISY_VAC_E Firmware Releases

STM32F405RGT6 + LAN9252 기반 **EtherCAT 슬레이브 산업용 I/O 모듈** `DAISY_VAC_E`의
펌웨어 바이너리 배포 저장소입니다.

> 이 저장소는 **빌드 산출물 배포 전용**입니다. 펌웨어 소스 코드는 별도의 비공개 저장소에서 관리됩니다.
> 모든 파일은 로그인 없이 익명으로 다운로드할 수 있습니다.

## 보드 구분 (FRONT / BACK)

동일한 소스에서 I/O 매핑이 다른 두 가지 바이너리가 빌드됩니다. **대상 보드에 맞는 파일을 사용해야 합니다.**

| 보드 | 빌드 정의 | 파일 접두사 |
|---|---|---|
| FRONT | `USE_FRONT` | `DAISY_VAC_E_Front` |
| BACK | `USE_BACK` | `DAISY_VAC_E_Back` |

## 파일 이름 규칙

파일 이름에 **릴리스 버전이 들어갑니다.**

```
DAISY_VAC_E_<보드>_<버전>.<확장자>      예) DAISY_VAC_E_Front_v2.0.0.hex
```

받아 둔 파일만 보고도 어느 버전인지 알 수 있고, 여러 버전을 한 폴더에 모아도
서로 덮어쓰지 않습니다. `v2.0.0` 이전(`v1.0.0`) 릴리스는 버전이 없는 옛 이름
(`DAISY_VAC_E_Front.hex`)을 씁니다.

## 최신 버전 다운로드

파일 이름이 버전마다 달라지므로 **`releases/latest/download/<파일명>` 형태의 고정 링크는
쓸 수 없습니다.** 아래 셋 중 하나를 쓰십시오.

1. **[최신 릴리스 페이지](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest)** 에서 직접 내려받기
2. 이 문서 아래 [릴리스 노트](#릴리스-노트) 표의 링크 (버전별 `hex` · `bin` · `elf`)
3. 스크립트에서는 **API로 최신 태그를 먼저 구해** 이름을 만듭니다 (인증 불필요)

```bash
# 예: BACK 보드 최신 .hex 내려받기
REPO=pjy4617/DAISY_VAC_E-firmware
TAG=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)
curl -L -O "https://github.com/$REPO/releases/download/$TAG/DAISY_VAC_E_Back_$TAG.hex"
```

파일명을 조립하지 않고 **자산 주소를 그대로 받는 방법**이 더 안전합니다.
버전 도입 이전 릴리스에도 그대로 통합니다.

```bash
curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
  | jq -r '.assets[] | select(.name | test("_Back(_.*)?\\.hex$")) | .browser_download_url' \
  | xargs curl -L -O
```

특정 버전이 필요하면 태그와 파일명을 함께 지정합니다.

```bash
curl -L -O https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Back_v2.0.0.hex
```

## 플래시 방법

[STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html)의 CLI를 사용합니다.

```bash
# .hex — 주소가 파일에 포함되어 있어 주소 지정이 필요 없습니다 (권장)
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back_v2.0.0.hex -hardRst -rst --start

# .bin — 플래시 시작 주소를 반드시 명시해야 합니다
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back_v2.0.0.bin 0x08000000 -hardRst -rst --start
```

## 무결성 검증

각 릴리스 노트에 모든 파일의 SHA-256 해시가 기록되어 있습니다.

```bash
sha256sum DAISY_VAC_E_Back_v2.0.0.hex
```

<!-- 아래 구간은 릴리스 게시 시 GitHub Actions가 자동으로 갱신합니다. 직접 수정하지 마세요. -->
<!-- RELEASES:START -->

## 릴리스 노트

| 버전 | 게시일 | FRONT | BACK |
|---|---|---|---|
| [v2.0.0](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/tag/v2.0.0) | 2026-08-08 | [hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Front.hex) · [bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Front.bin) · [elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Front.elf) | [hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Back.hex) · [bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Back.bin) · [elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v2.0.0/DAISY_VAC_E_Back.elf) |
| [v1.0.0](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/tag/v1.0.0) | 2026-08-06 | [hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Front.hex) · [bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Front.bin) · [elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Front.elf) | [hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Back.hex) · [bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Back.bin) · [elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Back.elf) |

<details>
<summary><b>v2.0.0</b> 상세 노트</summary>

### 변경 사항

- **릴리스 파일 이름에 버전을 넣었습니다** — `DAISY_VAC_E_<보드>_<버전>.<확장자>`
  (예: `DAISY_VAC_E_Front_v2.0.0.hex`). 받아 둔 파일만 보고 버전을 알 수 있고,
  여러 버전을 한 폴더에 모아도 서로 덮어쓰지 않습니다.
- **펌웨어 바이너리 내용은 v1.0.0과 동일합니다.** 클린 재빌드로 6개 산출물의
  SHA-256이 그대로 재현되는 것을 확인했습니다. 이번 릴리스의 변경은 배포 파일명
  규칙에 한정되며 동작 변경은 없습니다.
- 파일 이름이 버전마다 달라지므로 `releases/latest/download/<파일명>` 형태의 고정
  링크는 더 이상 쓸 수 없습니다. 스크립트에서는 API로 자산 주소를 조회하십시오
  (README "최신 버전 다운로드" 참고).

> 소스 커밋의 `dirty` 표기는 펌웨어 소스가 아니라, 같은 저장소에 아직 커밋되지 않은
> 별도 도구 폴더 때문입니다. `Core/`·`Port/`·`Drivers/`·`Ethercat/` 는 clean 상태입니다.

### 빌드 정보

| 항목 | 값 |
|---|---|
| 소스 커밋 | `ebb8eea (dirty)` (`feat/imp-gui-test`) |
| 빌드 프리셋 | `Debug-Front` (FRONT) / `Debug-Back` (BACK) |
| 빌드 시각 | 2026-08-08 10:18:33 KST |
| 타깃 MCU | STM32F405RGT6 |
| EtherCAT ESC | LAN9252 |
| 툴체인 | GCC: (GNU Tools for STM32 14.3.rel1.20251027-0700) 14.3.1 20250623 |

### 산출물 (SHA-256)

| 파일 | 크기 | SHA-256 |
|---|---:|---|
| `DAISY_VAC_E_Front_v2.0.0.elf` | 1.5M | `3699df053f756f3ecb923ee69d0bba52bb1efd314f137e60e0bb2a0b4afb08ec` |
| `DAISY_VAC_E_Back_v2.0.0.elf` | 1.5M | `00bc485c37ed9b34dc608390e587bba30a9aeddc5a973b182f9b995a7885c611` |
| `DAISY_VAC_E_Front_v2.0.0.bin` | 42.0K | `23c4216592d58d8af07dc51d50a2a9a87e7b1bf03f31d262a3b12b866b827dde` |
| `DAISY_VAC_E_Back_v2.0.0.bin` | 42.5K | `38a7df020991e3625d9c7e23e1c97599b985f8bb019d8473fc22668d6b988df9` |
| `DAISY_VAC_E_Front_v2.0.0.hex` | 118.1K | `07d621d91b131cd208cd30787e036b1349032eb8248221248da28b5d503d26d1` |
| `DAISY_VAC_E_Back_v2.0.0.hex` | 119.5K | `ed0c3b05e15fee635fe95b6ed3faebd4f854801b539d7b6e86e1edb67ea36b87` |

### 플래시

```bash
# BACK 보드
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back_v2.0.0.hex -hardRst -rst --start
# FRONT 보드
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Front_v2.0.0.hex -hardRst -rst --start
```

> FRONT/BACK 바이너리는 I/O 매핑이 다릅니다. 보드에 맞는 파일을 사용하세요.

</details>

<details>
<summary><b>v1.0.0</b> 상세 노트</summary>

### 변경 사항

- 전원 투입 시 모든 출력이 잠시 ON되는 현상 수정 (2026.8.4)

### 빌드 정보

| 항목 | 값 |
|---|---|
| 소스 커밋 | `ebb8eea` (`main`) |
| 빌드 프리셋 | `Debug-Front` (FRONT) / `Debug-Back` (BACK) |
| 빌드 시각 | 2026-08-04 00:47:43 KST |
| 타깃 MCU | STM32F405RGT6 |
| EtherCAT ESC | LAN9252 |
| 툴체인 | GCC: (GNU Tools for STM32 14.3.rel1.20251027-0700) 14.3.1 20250623 |

### 산출물 (SHA-256)

| 파일 | 크기 | SHA-256 |
|---|---:|---|
| `DAISY_VAC_E_Front.elf` | 1.5M | `3699df053f756f3ecb923ee69d0bba52bb1efd314f137e60e0bb2a0b4afb08ec` |
| `DAISY_VAC_E_Back.elf` | 1.5M | `00bc485c37ed9b34dc608390e587bba30a9aeddc5a973b182f9b995a7885c611` |
| `DAISY_VAC_E_Front.bin` | 42.0K | `23c4216592d58d8af07dc51d50a2a9a87e7b1bf03f31d262a3b12b866b827dde` |
| `DAISY_VAC_E_Back.bin` | 42.5K | `38a7df020991e3625d9c7e23e1c97599b985f8bb019d8473fc22668d6b988df9` |
| `DAISY_VAC_E_Front.hex` | 118.1K | `07d621d91b131cd208cd30787e036b1349032eb8248221248da28b5d503d26d1` |
| `DAISY_VAC_E_Back.hex` | 119.5K | `ed0c3b05e15fee635fe95b6ed3faebd4f854801b539d7b6e86e1edb67ea36b87` |

### 플래시

```bash
# BACK 보드
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back.hex -hardRst -rst --start
# FRONT 보드
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Front.hex -hardRst -rst --start
```

> FRONT/BACK 바이너리는 I/O 매핑이 다릅니다. 보드에 맞는 파일을 사용하세요.

</details>

<!-- RELEASES:END -->

## 라이선스 / 문의

배포된 바이너리는 지정된 하드웨어(`DAISY_VAC_E` FRONT/BACK 보드) 전용입니다.
문의는 [Issues](https://github.com/pjy4617/DAISY_VAC_E-firmware/issues)로 남겨주세요.
