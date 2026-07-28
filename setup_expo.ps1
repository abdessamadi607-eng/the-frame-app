npx create-expo-app temp-expo-app -t expo-template-blank-typescript --yes
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Get-ChildItem -Path temp-expo-app -Force | Where-Object { $_.Name -ne 'app.json' } | Copy-Item -Destination expo-app -Recurse -Force
Remove-Item -Path temp-expo-app -Recurse -Force

Set-Location -Path expo-app

npx expo install expo-av expo-sqlite react-native-mmkv zustand @google/generative-ai react-native-google-mobile-ads expo-dev-client
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

npx expo prebuild --clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
