@echo off
REM =======================================================
REM  Flutter Build Script - APK + AAB (Windows CMD version)
REM =======================================================

echo.
echo === Starting Flutter release build ===
echo.

REM --- Vérifie que Flutter est disponible ---
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Flutter command not found! Make sure Flutter is in your PATH.
    pause
    exit /b
)

REM --- Nettoyage ---
echo Cleaning project...
flutter clean
if %errorlevel% neq 0 (
    echo flutter clean failed!
    pause
    exit /b
)

REM --- Récupération des dépendances ---
echo Getting packages...
flutter pub get
if %errorlevel% neq 0 (
    echo flutter pub get failed!
    pause
    exit /b
)

REM --- Construction APK ---
echo Building release APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo APK build failed!
    pause
    exit /b
)

REM --- Construction App Bundle (.aab) ---
echo Building release App Bundle (.aab)...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo App Bundle build failed!
    pause
    exit /b
)

REM --- Résumé ---
echo.
echo === Build completed successfully ===
echo --------------------------------------------
echo APK : build\app\outputs\flutter-apk\app-release.apk
echo AAB : build\app\outputs\bundle\release\app-release.aab
echo --------------------------------------------
echo.

REM --- Ouvre le dossier de sortie ---
explorer build\app\outputs\
pause
exit /b
