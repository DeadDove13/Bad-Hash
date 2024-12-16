param(
    [Parameter(Mandatory=$false)]
    [string]$DictionaryPath = ".\common_passwords.txt"
)

# Define color codes and exit message
$colors = @{
    Error = "Red"
    Pass = "Green"
    Info = "Yellow"
    Description = "Yellow"
    Exit = "White"
}
$ExitMessage = "Press Enter to exit"

# ASCII Art and GitHub Information
$asciiArt = @"
_______       __       ________-   __    __       __        ________  __    __   
|   _  "\     /""\     |"      "\  /" |  | "\     /""\      /"       )/" |  | "\  
(. |_)  :)   /    \    (.  ___  :)(:  (__)  :)   /    \    (:   \___/(:  (__)  :) 
|:     \/   /' /\  \   |: \   ) || \/      \/   /' /\  \    \___  \   \/      \/  
(|  _  \\  //  __'  \  (| (___\ || //  __  \\  //  __'  \    __/  \\  //  __  \\  
|: |_)  :)/   /  \\  \ |:       :)(:  (  )  :)/   /  \\  \  /" \   :)(:  (  )  :) 
(_______/(___/    \___)(________/  \__|  |__/(___/    \___)(_______/  \__|  |__/  
"@
$githubText = "GitHub: DeadDove13"

# Display ASCII art, GitHub information, and script description
Write-Host $asciiArt -ForegroundColor DarkGreen
Write-Host $githubText -ForegroundColor $colors.Info
Write-Host "`nThis script attempts to crack a given hash using a dictionary-based approach." -ForegroundColor $colors.Description

# Load BouncyCastle for SHA-3
try {
    Add-Type -Path "$PSScriptRoot\BouncyCastle.Crypto.dll"
} catch {
    Write-Host "Error: BouncyCastle.Crypto.dll not found in the working directory. Exiting." -ForegroundColor $colors.Error
    exit
}

# Define Hashing Functions
function Get-Hash($InputString, $Algorithm) {
    $InputBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $HashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    if ($HashAlgorithm -eq $null) {
        Throw "Hash algorithm '$Algorithm' is not supported."
    }
    $HashBytes = $HashAlgorithm.ComputeHash($InputBytes)
    return ($HashBytes | ForEach-Object ToString x2) -join ""
}

function Compute-SHA3Hash($InputString, $BitLength) {
    # Use BouncyCastle's SHA3 implementation with variable bit lengths
    $inputBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $sha3 = switch ($BitLength) {
        224 { New-Object Org.BouncyCastle.Crypto.Digests.Sha3Digest(224) }
        256 { New-Object Org.BouncyCastle.Crypto.Digests.Sha3Digest(256) }
        384 { New-Object Org.BouncyCastle.Crypto.Digests.Sha3Digest(384) }
        512 { New-Object Org.BouncyCastle.Crypto.Digests.Sha3Digest(512) }
        default { Throw "Unsupported SHA-3 bit length: $BitLength" }
    }
    $sha3.BlockUpdate($inputBytes, 0, $inputBytes.Length)
    $outputBytes = New-Object byte[]($BitLength / 8) # Output size based on bit length
    $sha3.DoFinal($outputBytes, 0)
    return ($outputBytes | ForEach-Object ToString x2) -join ""
}

function Compute-Hash($String, $Algorithm, $BitLength) {
    switch ($Algorithm.ToUpper()) {
        "MD5"    { return Get-Hash $String "MD5" }
        "SHA1"   { return Get-Hash $String "SHA1" }
        "SHA256" { return Get-Hash $String "SHA256" }
        "SHA3"   { return Compute-SHA3Hash $String $BitLength }
        default  { Throw "Unsupported hash type specified." }
    }
}

while ($true) {
    # User Inputs
    if (-not (Test-Path $DictionaryPath)) {
        Write-Host "Dictionary file not found at $DictionaryPath. Exiting." -ForegroundColor $colors.Error
        exit
    }
    Write-Host "Using dictionary file: $DictionaryPath" -ForegroundColor $colors.Info

    $TargetHash = Read-Host "Enter the hash value you want to crack"
    $Salt = Read-Host "Enter the salt if there is one (leave blank if none)"

    # Ensure salt is a string and trim whitespace
    $Salt = [string]$Salt
    $Salt = $Salt.Trim()

    # Safely handle negative salts or numeric-looking salts
    if ($Salt -match "^-?\d+$") {  # Detect negative/positive numbers
        $Salt = "`"$Salt`""       # Wrap salt in quotes to ensure proper concatenation
    }

    if ([string]::IsNullOrEmpty($Salt)) {
        $Salt = ""
        Write-Host "No salt provided." -ForegroundColor $colors.Info
    } else {
        Write-Host "Using salt: $Salt" -ForegroundColor $colors.Info
    }

    # Identify hash type by length
    $hashLength = $TargetHash.Length
    $hashType = $null
    $bitLength = 0

    switch ($hashLength) {
        32 { $hashType = "MD5" }
        40 { $hashType = "SHA1" }
        56 { $hashType = "SHA3"; $bitLength = 224 }
        64 {
            Write-Host "The hash length (64) matches both SHA-256 and SHA-3(256)." -ForegroundColor $colors.Info
            $choice = Read-Host "Enter '1' for SHA-256 or '2' for SHA-3(256)"
            if ($choice -eq '1') {
                $hashType = "SHA256"
            } elseif ($choice -eq '2') {
                $hashType = "SHA3"; $bitLength = 256
            } else {
                Write-Host "Invalid choice. Exiting." -ForegroundColor $colors.Error
                exit
            }
        }
        96 { $hashType = "SHA3"; $bitLength = 384 }
        128 { $hashType = "SHA3"; $bitLength = 512 }
        default {
            Write-Host "Unknown hash length: $hashLength. Unable to determine algorithm." -ForegroundColor $colors.Error
            exit
        }
    }

    Write-Host "Detected hash type: $hashType ($bitLength-bit)" -ForegroundColor $colors.Info
    Write-Host "Attempting to crack hash..." -ForegroundColor $colors.Info

    # Attempt dictionary-based cracking
    $passwords = Get-Content $DictionaryPath
    $found = $false
    $totalLines = $passwords.Count
    $currentLine = 0

    foreach ($password in $passwords) {
        $currentLine++
        if ($currentLine % 500 -eq 0) {
            $progress = [math]::Round(($currentLine / $totalLines) * 100, 2)
            Write-Progress -Activity "Cracking Hash" -Status "$progress% Complete" -PercentComplete $progress
        }
        
        $testString = $password + [string]$Salt
        $testHash = Compute-Hash $testString $hashType $bitLength

        if ($testHash -eq $TargetHash.ToLower()) {
            Write-Host "Hash cracked! Password is: $password" -ForegroundColor $colors.Pass
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "No match found in dictionary." -ForegroundColor $colors.Error
    }
    
    Write-Host "1: Run again" -ForegroundColor $colors.Info
    Write-Host "2: Exit" -ForegroundColor $colors.Info
    $option = Read-Host "Enter your choice"
    if ($option -eq '2') {
        Write-Host "Exiting. Goodbye!" -ForegroundColor $colors.Exit
        break
    } else {
        Clear-Host
        Write-Host $asciiArt -ForegroundColor DarkGreen
        Write-Host $githubText -ForegroundColor $colors.Info
        Write-Host "`nThis script attempts to crack a given hash using a dictionary-based approach." -ForegroundColor $colors.Description
    }
}
