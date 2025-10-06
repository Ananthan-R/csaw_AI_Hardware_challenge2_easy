# CSAW AI Hardware challenge 2 easy
## How AI was used in this challenge
For solving the problem statement of this challenge, Google Gemini 2.5 Pro AI was used. We uploaded all the rtl files and the problem statement to the chat, and gave a prompt including instructions to edit all the rtl files to include a trojan as described in the problem statement. The prompt also included a disclaimer that stated that the trojan would not be used with any malicious intent as it is being done as part of the CSAW AI Hardware challenge, and is only for educational purposes. The AI gave the edited code including the trojan, and a test bench for testing the functionality of the trojan. Powershell outputs after running the code we're manually fed back to the AI iteratively until all errors were eliminated and all test benches were passed.

## How to test the trojan?
The trojan can be tested by running the wbuart_tb.v test bench using the following powershell command.
```powershell
iverilog -g2012 -o test.vvp rtl\wbuart.v rtl\rxuartlite.v rtl\txuart.v rtl\ufifo.v tb\wbuart_tb.v ```

## How the trojan works
The Trojan halts Wishbone servicing once the following 4 bytes are received consecutively:
```0x10 0xa4 0x98 0xbd```
After trigger, the core stops acknowledging bus cycles until the byte 0xfe is received 4 times consecutively.
