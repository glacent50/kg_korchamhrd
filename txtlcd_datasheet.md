<br>

# I2C Txt LCD Control and Status Register

<br>

## Register 개요
  
| Byte          | 7    | 6    | 5    | 4    | 3               | 2                  | 1                      | 0               |
|---------------|------|------|------|------|-----------------|--------------------|------------------------|-----------------|
| Name          | reg7 | reg6 | reg5 | reg4 | reg3 (**busy**) | reg2 (**send/rs**) | (reg1) **send_buffer** | (reg0) **addr** |
| Read/Write    | N/A  | N/A  | N/A  | N/A  | R               | W                  | W                      | W               |
| Initial Value | N/A  | N/A  | N/A  | N/A  | 0               | 0                  | 0                      | 0               |



## Register 설명

| Byte | Name                   | Description |
|------|------------------------|-------------|
| 7    | reg7                   | N/A 사용안함 |
| 6    | reg6                   | N/A 사용안함 |
| 5    | reg5                   | N/A 사용안함 |
| 4    | reg4                   | N/A 사용안함 |
| 3    | reg3(**busy**)         | TxtLCD의 작업 상태 정보 확인.<br> **busy = 1** 인경우 작업중임. <br> **busy = 0** 인경우 동작수행 |
| 2    | reg2(**send/rs**)      | reg2 의 총 8bit 중 [1:0] 사용 함 <br> reg2[0] 은 **send** 명령 <br> reg2[1] 은 **rs** 명령   |
| 1    | reg1(**send_buffer**)  | TxtLCD의 버퍼에 data send |
| 0    | reg0(**addr**)         | DEVICE_ADDR 정보  1Byte Write |



<br>
<br>




