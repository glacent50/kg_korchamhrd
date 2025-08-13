# multi_mode_watch 회로도 (Mermaid)

아래 다이어그램은 `multi_mode_watch` 상위 모듈의 블록 연결과 모드 전이(State) 동작을 나타냅니다. 필요 시 블록/연결명을 수정해 회로도를 업데이트하세요.

## 블록 다이어그램

```mermaid
flowchart LR
    %% I/O
    CLK["clk"]
    RST["reset_p"]
    BTN["btn[3:0]"]

    %% 버튼 분기
    BTN3["btn[3]"]
    BTN_LOWER["btn[2:0]"]

    BTN -->|상위비트| BTN3
    BTN -->|하위비트| BTN_LOWER

    %% 엣지 검출 버튼 카운터
    subgraph BTN_CNTR[btn_cntr mode_btn]
      direction TB
      BC["btn_cntr\n(.clk, .reset_p, .btn=btn[3])"]
      PEDGE["btn_mode (p-edge)"]
    end

    %% 모드 레지스터
    subgraph MODE_REG[mode register 00/01/10]
      direction TB
      MODE[(mode_reg)]
    end

    %% 서브모듈 영역
    subgraph WATCH[watch_top]
      direction TB
      WTOP["watch_top\n(.clk, .reset_p, .btn=btn[2:0])"]
      W_SEG["watch_seg_7[7:0]"]
      W_COM["watch_com[3:0]"]
      W_LED["watch_led[15:0]"]
      WTOP --> W_SEG
      WTOP --> W_COM
      WTOP --> W_LED
    end

    subgraph CT[cook_timer]
      direction TB
      CTOP["cook_timer\n(.clk, .reset_p, .btn=btn[3:0])"]
      C_SEG["cook_timer_seg_7[7:0]"]
      C_COM["cook_timer_com[3:0]"]
      C_LED["cook_timer_led[15:0]"]
      C_ALM["cook_timer_alarm"]
      CTOP --> C_SEG
      CTOP --> C_COM
      CTOP --> C_LED
      CTOP --> C_ALM
    end

    subgraph SW[stop_watch]
      direction TB
      STOP["stop_watch\n(.clk, .reset_p, .btn=btn[2:0])"]
      S_SEG["stop_watch_seg_7[7:0]"]
      S_COM["stop_watch_com[3:0]"]
      S_LED["stop_watch_led[15:0]"]
      STOP --> S_SEG
      STOP --> S_COM
      STOP --> S_LED
    end

    %% 입력 연결
    CLK --> BC
    RST --> BC
    BTN3 --> BC

    CLK --> WTOP
    RST --> WTOP
    BTN_LOWER --> WTOP

    CLK --> CTOP
    RST --> CTOP
    BTN --> CTOP

    CLK --> STOP
    RST --> STOP
    BTN_LOWER --> STOP

    %% 모드 선택
    BC -->|btn_mode| MODE

    %% 출력 MUX (mode에 따라 3:1 선택)
    subgraph MUX[output multiplexer]
      direction TB
      MUX_SEG{{"seg_7 3:1 MUX"}}
      MUX_COM{{"com 3:1 MUX"}}
      MUX_LED{{"led 3:1 MUX"}}
      MUX_ALM{{"alarm select"}}
    end

    MODE --> MUX_SEG
    MODE --> MUX_COM
    MODE --> MUX_LED
    MODE --> MUX_ALM

    W_SEG --> MUX_SEG
    C_SEG --> MUX_SEG
    S_SEG --> MUX_SEG

    W_COM --> MUX_COM
    C_COM --> MUX_COM
    S_COM --> MUX_COM

    W_LED --> MUX_LED
    C_LED --> MUX_LED
    S_LED --> MUX_LED

    %% alarm: cook_timer만 활성, 나머지는 0
    C_ALM --> MUX_ALM

    %% 최종 출력
    SEG_OUT["seg_7[7:0]"]
    COM_OUT["com[3:0]"]
    LED_OUT["led[15:0]"]
    ALM_OUT["alarm"]

    MUX_SEG --> SEG_OUT
    MUX_COM --> COM_OUT
    MUX_LED --> LED_OUT
    MUX_ALM --> ALM_OUT

    %% 주석/라벨
  classDef note fill:#f7f7f7,stroke:#bbb,color:#333;
  N1[mode mapping: 00=watch, 01=cook_timer, 10=stop_watch]:::note
    MODE --- N1
```

## 모드 상태도 (btn_mode 상승엣지로 순환)

```mermaid
stateDiagram-v2
    [*] --> S00
    S00: 00 (watch)
    S01: 01 (cook_timer)
    S10: 10 (stop_watch)

    S00 --> S01: btn_mode (rising)
    S01 --> S10: btn_mode (rising)
    S10 --> S00: btn_mode (rising)

    note right of S00
      initial value: 00
      reset_p maintains initial value (no change in async reset block)
    end note
```

### 비고
- alarm은 cook_timer에서만 유효하며, watch/stop_watch에서는 0으로 강제됩니다.
- 버튼 디바운스/엣지 검출은 `btn_cntr`에서 처리하며, `btn[3]`의 상승엣지로 모드가 순환합니다.
- 각 서브모듈의 세부 핀/동작은 해당 모듈 정의에 따릅니다.
