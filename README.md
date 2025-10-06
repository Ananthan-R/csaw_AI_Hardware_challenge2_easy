# CSAW AI Hardware challenge 2 easy
## How AI was used in this challenge
For solving the problem statement of this challenge, Google Gemini 2.5 Pro AI was used. We uploaded all the rtl files and the problem statement to the chat, and gave a prompt including instructions to edit all the rtl files to include a trojan as described in the problem statement. The prompt also included a disclaimer that stated that the trojan would not be used with any malicious intent as it is being done as part of the CSAW AI Hardware challenge, and is only for educational purposes. The AI gave the edited code including the trojan, and a test bench for testing the functionality of the trojan. Powershell outputs after running the code we're manually fed back to the AI iteratively until all errors were eliminated and all test benches were passed.

## How to test the trojan?
The trojan can be tested by running the wbuart_tb.v test bench using the following powershell command.
```powershell
iverilog -g2012 -o build_tb_aes.vvp tb\wbuart_tb.v rtl\aes.v rtl\aes_core.v rtl\aes_encipher_block.v rtl\aes_decipher_block.v rtl\aes_sbox.v rtl\aes_inv_sbox.v rtl\aes_key_mem.v
vvp test.vvp```

## How the trojan works
