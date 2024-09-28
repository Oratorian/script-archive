# Specify the correct path to your BCrypt.Net-Next.dll file
$bcryptDllPath = "BCrypt.Net-Next.dll"

# Check if the DLL exists
if (-not (Test-Path $bcryptDllPath)) {
    Write-Error "The BCrypt.Net DLL file was not found at the specified path: $bcryptDllPath"
    Exit
}

# Use System.IO.File to read the DLL as a byte array
[byte[]]$dllBytes = [System.IO.File]::ReadAllBytes($bcryptDllPath)

# Ensure that the byte array is not null or empty
if ($dllBytes -eq $null -or $dllBytes.Length -eq 0) {
    Write-Error "Failed to read the BCrypt.Net DLL file. The byte array is null or empty."
    Exit
}

# Convert the byte array to a Base64 string
$base64Dll = [Convert]::ToBase64String($dllBytes)

# Save the Base64 string to a file (optional)
$base64Dll | Set-Content "bcryptDllBase64.txt"

Write-Host "DLL successfully converted to Base64 and saved to bcryptDllBase64.txt"
