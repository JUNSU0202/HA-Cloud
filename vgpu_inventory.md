# vgpu\_inventory.sh 스크립트 메뉴얼

## 1\. 📋 개요

이 스크립트는 OpenStack 환경에서 VGPU(가상 GPU) 리소스의 현재 사용 현황을 조회하기 위해 설계되었습니다.

특히 `gpu01_pci_`라는 이름 패턴을 가진 특정 리소스 제공자(Resource Provider)들을 대상으로 하여, 각 제공자별 VGPU의 **총량(Total)**, **사용량(Used)**, \*\*예약량(Reserved)\*\*을 터미널에 표(Table) 형태로 출력합니다.

## 2\. ⚙️ 사전 요구사항

스크립트가 정상적으로 작동하기 위해 다음 환경이 필요합니다.

  * **OpenStack CLI (`python-openstackclient`):** `openstack` 명령어가 설치되어 있어야 합니다.
  * **인증 (Authentication):** 스크립트를 실행하는 환경에 OpenStack 인증 정보 (예: `openrc.sh` 파일)가 로드되어 있어야 합니다. (`openstack` 명령이 인증 오류 없이 실행 가능해야 함)
  * **필요 권한:** `openstack resource provider list` 및 `openstack resource provider inventory list` 명령을 실행할 수 있는 충분한 권한 (보통 admin)이 필요합니다.
  * **필수 유틸리티:** `grep`, `sort`, `awk` 등 기본적인 쉘 유틸리티가 필요합니다. (대부분의 Linux 배포판에 기본 설치되어 있습니다.)

## 3\. 📜 스크립트 원본 (`vgpu_inventory.sh`)

```bash
#!/bin/bash

# Print header
echo -e "Provider Name\tUUID\t\t\t\t\t\tTotal VGPU\tUsed VGPU\tReserved VGPU"

# Get provider list starting with gpu01_pci_, sorted by provider name
openstack resource provider list -f value | grep 'gpu01_pci_' | sort -k2 | while read uuid name rest; do
  # Fetch inventory for each provider
  inventory=$(openstack resource provider inventory list $uuid -f value | grep VGPU)

  # If VGPU inventory exists, parse the total, used, and reserved
  if [ -n "$inventory" ]; then
    total=$(echo $inventory | awk '{print $7}')
    used=$(echo $inventory | awk '{print $8}')
    reserved=$(echo $inventory | awk '{print $5}')

    # Print the result in tab-separated format
    echo -e "$name\t$uuid\t$total\t\t$used\t\t$reserved"
  else
    echo -e "$name\t$uuid\tNo VGPU\t\tNo VGPU\t\tNo VGPU"
  fi
done
```

## 4\. 🚀 사용 방법

1.  **파일 저장:** 위 내용을 `vgpu_inventory.sh` 이름으로 저장합니다.

2.  **실행 권한 부여:**

    ```shell
    chmod +x vgpu_inventory.sh
    ```

3.  **스크립트 실행:** (OpenStack 인증 정보가 로드된 터미널에서)

    ```shell
    ./vgpu_inventory.sh
    ```

## 5\. 🛠️ 주요 동작 설명

스크립트는 다음 순서로 작동합니다.

1.  **헤더 출력:**

      * `echo -e` 명령을 사용해 결과로 출력될 표의 제목 행(컬럼 이름)을 먼저 출력합니다.

2.  **리소스 제공자 목록 조회 및 필터링:**

      * `openstack resource provider list -f value`: OpenStack의 모든 리소스 제공자를 값(value) 형식으로 가져옵니다.
      * `grep 'gpu01_pci_'`: 이름에 `gpu01_pci_`가 포함된 제공자만 필터링합니다. (특정 호스트 또는 GPU 그룹을 대상으로 함)
      * `sort -k2`: 목록을 두 번째 필드(제공자 이름) 기준으로 정렬합니다.

3.  **반복문 실행:**

      * `while read uuid name rest; do ... done` 구문을 통해 필터링된 각 제공자(Provider)를 한 줄씩 읽어 `uuid`와 `name` 변수에 할당합니다.
      * (참고: `openstack ... -f value`의 출력 순서가 'UUID'가 'Name'보다 먼저 나오므로 `uuid` 변수에 UUID가, `name` 변수에 이름이 저장됩니다.)

4.  **VGPU 인벤토리 조회:**

      * `inventory=$(...)`: 각 제공자의 `uuid`를 사용해 `openstack resource provider inventory list $uuid -f value` 명령으로 인벤토리 목록을 가져옵니다.
      * `grep VGPU`: 인벤토리 중 `VGPU` 리소스 클래스에 해당하는 줄만 `inventory` 변수에 저장합니다.

5.  **결과 파싱 및 출력:**

      * `if [ -n "$inventory" ]; then`: VGPU 인벤토리 정보가 존재하는지(`$inventory` 변수가 비어있지 않은지) 확인합니다.
      * **(VGPU 정보가 있을 경우):**
          * `awk`를 사용해 `inventory` 변수의 공백으로 구분된 필드에서 VGPU 정보를 추출합니다.
          * `awk '{print $5}'`: 5번째 필드 (`Reserved`)
          * `awk '{print $7}'`: 7번째 필드 (`Total`)
          * `awk '{print $8}'`: 8번째 필드 (`Used`)
      * **(VGPU 정보가 없을 경우):**
          * `No VGPU` 메시지를 해당 행에 출력합니다.
      * `echo -e ...`: `name`, `uuid` 및 추출된 VGPU 값들을 탭(`\t`)으로 구분하여 최종 결과 한 줄을 출력합니다.

## 6\. 📊 출력 예시

스크립트를 실행하면 다음과 유사한 탭(tab)으로 구분된 텍스트가 출력됩니다.

```
Provider Name                 UUID                                  Total VGPU      Used VGPU       Reserved VGPU
gpu01_pci_0000_3b_00_0        a1b2c3d4-e5f6-7890-1234-567890abcdef    8               2               0
gpu01_pci_0000_3c_00_0        b2c3d4e5-f6a7-8901-2345-67890abcdef1    8               0               0
gpu01_pci_0000_86_00_0        c3d4e5f6-a7b8-9012-3456-7890abcdef12    8               8               0
gpu01_pci_0000_87_00_0        d4e5f6a7-b8c9-0123-4567-890abcdef123    No VGPU         No VGPU         No VGPU
```

*(참고: UUID와 값, `Provider Name`의 순서는 실제 환경에 따라 다르게 표시될 수 있습니다.)*

## 7\. 🔧 참고 및 수정 사항

  * **조회 대상 변경:**

      * `grep 'gpu01_pci_'` 부분을 수정하여 다른 이름 패턴을 가진 리소스 제공자를 조회할 수 있습니다.
      * 예: `gpu02` 서버의 GPU를 보려면 `grep 'gpu02_pci_'`
      * 예: 모든 PCI 기반 GPU를 보려면 `grep '_pci_'`

  * **출력 정렬:**

      * `echo -e` 라인의 `\t` (탭) 개수를 조절하여 출력되는 표의 간격을 맞출 수 있습니다.
