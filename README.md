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

## 최신 버전 다운로드

아래 링크는 **항상 최신 릴리스**를 가리킵니다. 스크립트에서 그대로 사용할 수 있습니다.

| 파일 | FRONT | BACK |
|---|---|---|
| `.hex` (플래시 권장) | [DAISY_VAC_E_Front.hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Front.hex) | [DAISY_VAC_E_Back.hex](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Back.hex) |
| `.bin` | [DAISY_VAC_E_Front.bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Front.bin) | [DAISY_VAC_E_Back.bin](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Back.bin) |
| `.elf` (디버깅/심볼) | [DAISY_VAC_E_Front.elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Front.elf) | [DAISY_VAC_E_Back.elf](https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Back.elf) |

```bash
# 예: BACK 보드 최신 펌웨어 내려받기 (인증 불필요)
curl -L -O https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/latest/download/DAISY_VAC_E_Back.hex
```

특정 버전이 필요하면 `latest/download` 자리에 `download/<태그>`를 넣습니다.

```bash
curl -L -O https://github.com/pjy4617/DAISY_VAC_E-firmware/releases/download/v1.0.0/DAISY_VAC_E_Back.hex
```

## 플래시 방법

[STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html)의 CLI를 사용합니다.

```bash
# .hex — 주소가 파일에 포함되어 있어 주소 지정이 필요 없습니다 (권장)
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back.hex -hardRst -rst --start

# .bin — 플래시 시작 주소를 반드시 명시해야 합니다
STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back.bin 0x08000000 -hardRst -rst --start
```

## 무결성 검증

각 릴리스 노트에 모든 파일의 SHA-256 해시가 기록되어 있습니다.

```bash
sha256sum DAISY_VAC_E_Back.hex
```

<!-- 아래 구간은 릴리스 게시 시 GitHub Actions가 자동으로 갱신합니다. 직접 수정하지 마세요. -->
<!-- RELEASES:START -->

_아직 게시된 릴리스가 없습니다._

<!-- RELEASES:END -->

## 라이선스 / 문의

배포된 바이너리는 지정된 하드웨어(`DAISY_VAC_E` FRONT/BACK 보드) 전용입니다.
문의는 [Issues](https://github.com/pjy4617/DAISY_VAC_E-firmware/issues)로 남겨주세요.
