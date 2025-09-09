# ADC Control and Status Register A


## ADCSRA Register Overview

| Bit | 7    | 6    | 5    | 4    | 3    | 2    | 1    | 0    |
|-----|------|------|------|------|------|------|------|------|
| Name | ADEN | ADSC | ADFR | ADIF | ADIE | ADPS2 | ADPS1 | ADPS0 |
| Read/Write | R/W  | R/W  | R/W  | R/W  | R/W  | R/W   | R/W   | R/W   |
| Initial Value | 0    | 0    | 0    | 0    | 0    | 0     | 0     | 0     |



## Register Description

| Bit | Name  | Description |
|-----|-------|-------------|
| 7   | ADEN  | ADC Enable: Writing this bit to one enables the ADC. Writing it to zero turns off the ADC. Turning the ADC off while a conversion is in progress will terminate the conversion. |
| 6   | ADSC  | ADC Start Conversion: In Single Conversion mode, write this bit to one to start each conversion. In Free Running mode, write this bit to one to start the first conversion. The first conversion after ADSC has been enabled will take 25 ADC clock cycles instead of the normal 13. ADSC will read as one as long as a conversion is in progress. When the conversion is complete, it returns to zero. |
| 5   | ADATE | ADC Free Running Select: When this bit is written to one, the ADC operates in Free Running mode, continuously sampling and updating the data registers. Writing zero to this bit will terminate Free Running mode. |
| 4   | ADIF  | ADC Interrupt Flag: This bit is set when an ADC conversion completes and the data registers are updated. The ADC Conversion Complete Interrupt is executed if the ADIE bit and the I-bit in SREG are set. ADIF is cleared by writing a logical one to the flag. |
| 3   | ADIE  | ADC Interrupt Enable: When this bit is written to one and the I-bit in SREG is set, the ADC Conversion Complete Interrupt is activated. |
| 2-0 | ADPS2:0 | ADC Prescaler Select Bits: These bits determine the division factor between the XTAL frequency and the input clock to the ADC. |

## ADC Prescaler Selections

| ADPS2 | ADPS1 | ADPS0 | Division Factor |
|-------|-------|-------|-----------------|
| 0     | 0     | 0     | 2               |
| 0     | 0     | 1     | 4               |
| 0     | 1     | 0     | 8               |
| 0     | 1     | 1     | 16              |
| 1     | 0     | 0     | 32              |
| 1     | 0     | 1     | 64              |
| 1     | 1     | 0     | 128             |

