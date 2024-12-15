# Fun Project: Hash Cracking Script

This repository contains a PowerShell script that attempts to crack a given hash using a dictionary-based approach. It's an experimental and fun project to explore hash algorithms and scripting techniques. While the script is functional, **there are far better tools available for hash cracking**, so this project is primarily for educational and entertainment purposes.

## What This Is
This project is:
- A dictionary-based hash cracking tool written in PowerShell.
- A learning exercise to understand hash functions like MD5, SHA1, SHA256, and SHA3.
- Not intended for serious or production use.

## Why There Are Better Options
Professional tools like Hashcat or John the Ripper are:
- Faster and more efficient.
- Capable of handling more complex hash types and scenarios.
- Actively maintained by expert communities.

This script is more of a fun side project and is not designed to compete with professional tools.

## How to Use
1. Clone the repository:
    ```bash
    gh repo clone DeadDove13/Bad-Hash
    ```
2. Ensure you have the required dictionary file (`common_passwords.txt`) and the `BouncyCastle.Crypto.dll` file in the working directory.
3. Run the script in PowerShell:
    ```powershell
    .\HashCracker.ps1
    ```
4. Follow the prompts to input the hash value, optional salt, and dictionary file path.
---

If you find this interesting or have ideas for improvement, feel free to fork and experiment!
