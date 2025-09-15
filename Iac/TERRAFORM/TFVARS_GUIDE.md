# Terraform 변수 가이드 (`terraform.tfvars`)

이 가이드는 `terraform.tfvars` 파일을 사용하여 Terraform 배포를 위한 변수를 정의하는 방법을 설명합니다.

`variables.tf`에 선언된 **모든 변수**는 `terraform.tfvars` 파일, 명령줄 인수(`-var`), 또는 환경 변수(`TF_VAR_`)를 통해 **반드시** 제공되어야 합니다. `terraform.tfvars` 파일을 사용하는 것이 가장 권장되는 방법입니다.

## `terraform.tfvars` 사용 방법

1.  `Iac/TERRAFORM` 디렉토리에 `terraform.tfvars`라는 이름의 파일을 생성합니다.
2.  `key = "value"` 형식으로 필요한 변수를 이 파일에 정의합니다.

## 필수 변수

아래는 모든 필수 변수와 일반적인 값의 목록입니다. 이 블록을 `terraform.tfvars` 파일에 복사하고 적절한 값으로 채워 넣으십시오.

```terraform
aws_region = "your_aws_region" # 예: "ap-northeast-2"
project_name = "your_project_name" # 예: "MyDockerSwarm"
vpc_cidr = "your_vpc_cidr" # 예: "10.0.0.0/16"
az_a = "your_az_a" # 예: "ap-northeast-2a"
az_b = "your_az_b" # 예: "ap-northeast-2c"
public_subnet_a_cidr = "your_public_subnet_a_cidr" # 예: "10.0.1.0/24"
public_subnet_b_cidr = "your_public_subnet_b_cidr" # 예: "10.0.2.0/24"
private_subnet_a_cidr = "your_private_subnet_a_cidr" # 예: "10.0.101.0/24"
private_subnet_b_cidr = "your_private_subnet_b_cidr" # 예: "10.0.102.0/24"
instance_type = "your_instance_type" # 예: "t3.micro"
ssh_key_name = "your_ssh_key_name" # 예: "my-ssh-key"
ssh_key_file_path = "your_ssh_key_file_path" # 예: "~/.aws/key/my-ssh-key.pem"
my_ip = "your_public_ip/32" # 중요: SSH 접속을 허용할 본인의 공용 IP 주소로 변경하십시오. 예: "203.0.113.45/32"
manager_ip = "your_manager_private_ip" # 예: "10.0.101.10"
worker_nodes = {
  "worker1" = { ip = "your_worker1_private_ip", subnet_cidr = "your_worker1_subnet_cidr" }, # 예: "10.0.102.10", "10.0.102.0/24"
  "worker2" = { ip = "your_worker2_private_ip", subnet_cidr = "your_worker2_subnet_cidr" }  # 예: "10.0.101.11", "10.0.101.0/24"
}
```

## `terraform.tfvars` 예시

```terraform
aws_region = "ap-northeast-2"
project_name = "MyDockerSwarm"
vpc_cidr = "10.0.0.0/16"
az_a = "ap-northeast-2a"
az_b = "ap-northeast-2c"
public_subnet_a_cidr = "10.0.1.0/24"
public_subnet_b_cidr = "10.0.2.0/24"
private_subnet_a_cidr = "10.0.101.0/24"
private_subnet_b_cidr = "10.0.102.0/24"
instance_type = "t3.micro"
ssh_key_name = "my-ssh-key"
ssh_key_file_path = "your_ssh_key_file_path" # Changed to placeholder
my_ip = "your_public_ip/32" # Changed to placeholder
manager_ip = "10.0.101.10"
worker_nodes = {
  "worker1" = { ip = "10.0.102.10", subnet_cidr = "10.0.102.0/24" },
  "worker2" = { ip = "10.0.101.11", subnet_cidr = "10.0.101.0/24" }
}
```

**참고:** 보안을 위해 `terraform.tfvars` 파일을 `.gitignore`에 추가하는 것을 권장합니다.