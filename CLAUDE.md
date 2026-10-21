# TikTok iOS Mod

Свой iOS-мод TikTok на основе https://github.com/raulsaeed/BHTikTokPlusPlus (Theos-твик BHTikTok).
IPA собирается в GitHub Actions (macOS-раннер), т.к. у владельца Windows без macOS/Xcode.

## Правила
- Работаем только на диске D. Диск C не используем ни в коем случае (файлы, кэши, temp, глобальные настройки).
- Основная работа идёт через субагентов на Haiku 5.5 (`.claude/agents/builder.md`, `.claude/settings.json`).

## Цели
- Твик на базе BHTikTokPlusPlus, собирается в IPA через GitHub Actions.
- Рекомендации в России без VPN: смена региона (CTCarrier mcc/mnc, store region, TIKTOKRegionManager и др.) включена по умолчанию на не-российский регион.
- На будущее: https://glass3d.dev (генератор 3D-стекла) — для иконки и, возможно, оформления интерфейса мода.
- GitHub: публичный репозиторий `finrigit/TTF-Mod-iOS`. git — `D:\Tools\Git\cmd\git.exe`, gh — `D:\Tools\gh\bin\gh.exe`; перед командами задавать `$env:GH_CONFIG_DIR='D:\Tools\gh-config'`, `$env:GIT_CONFIG_GLOBAL='D:\Tools\gh-config\gitconfig'`, `$env:TEMP`/`$env:TMP`=`D:\Temp`.
- Соседний проект `D:\TikTok Mod` — десктопный клиент на Electron, это другой проект.
