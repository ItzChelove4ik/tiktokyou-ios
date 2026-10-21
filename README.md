# TikTok You (iOS)

iOS-порт мода **TikTok You** (Android v5.0 на базе TikTok 47.4.3) на технической базе
[TTF-Mod-iOS](https://github.com/finrigit/TTF-Mod-iOS) / BHTikTokPlusPlus (Theos, сборка в GitHub Actions).

Мод-меню, строки, фичи и структура — из Android-мода TikTok You. Сборка: GitHub Actions →
unsigned IPA → подпись через Sideloadly на Windows.

## Возможности (перенесённые)

- **Скрытие**: реклама, трансляции, фото-слайдшоу, истории, мини-сериалы, платный контент
- **Фильтры контента**: слова/теги, минимум лайков, просмотров, дата публикации
- **Регион**: подмена региона (по умолчанию Казахстан — рекомендации в РФ без VPN), пикер на 194 страны
- **Скачивание**: видео без watermark, HD, музыка, фото
- **Воспроизведение**: прогресс-бар (перемотка) везде
- **Антивыгорание**: затемнение интерфейса ленты (прозрачность настраивается)
- **Прочее**: чистка трекинг-параметров ссылок, ссылки в Safari, UID-копирование, лог хуков

Вызов меню: **долгое нажатие на плавающую кнопку** (внизу справа) или
TikTok → Настройки → **Настройки TikTok You**.

Неперенесённые фичи и риски: см. `docs/BLOCKERS.md`.

## Как собрать IPA (GitHub Actions)

1. Создайте свой репозиторий (private) и загрузите в него эти файлы
   (или используйте этот репозиторий).
2. **Расшифрованный (decrypted) TikTok IPA** загрузите в **черновик релиза `tiktok-ipa`**:
   Releases → Draft a new release → tag `tiktok-ipa` → attach `.ipa`
   (или `gh release create tiktok-ipa --draft "TikTok.ipa"`, затем upload).
3. Откройте **Actions** → workflow **Build TikTok You IPA** → **Run workflow**.
   Параметры: `display_name` (по умолчанию «TikTok You»), `icon_variant` (default/metal/hlx/md).
4. Дождитесь окончания (15–30 минут). Скачайте артефакт **TikTokYou-ipa** → `TikTokYou.ipa`.
5. Подробная инструкция по установке: `docs/INSTALL.md`.

Важно: IPA должен быть расшифрованным, иначе инжекция не сработает.
Ссылки на IPA не публикуйте.

## Структура

- `Tweak.x` — хуки фич + группы + %ctor (runtime-проверки классов)
- `TweakDownload.x` — кнопка скачивания и загрузка медиа
- `BHIManager.m/.h` — настройки (ключи как в Android TikTok You) + HookLog
- `RegionInfo.m` — 194 региона (RU-названия, ISO)
- `YouSettingsViewController.m` — мод-меню TikTok You (тёмная тема, секции 1:1)
- `YouFloatingHub.m` — плавающая кнопка (антивыгорание + меню)
- `YouRegionPicker/YouFilterWords/YouHookLogVC` — вспомогательные экраны
- `tools/replace_icon.py` — замена иконки приложения в IPA
- `tools/qa_ipa.py` — QA-проверки IPA (структура, dylib, хукаемые классы)
- `.github/workflows/build.yml` — сборка

## Благодарности

- База: [TTF-Mod-iOS](https://github.com/finrigit/TTF-Mod-iOS) ← [BHTikTokPlusPlus](https://github.com/raulsaeed/BHTikTokPlusPlus) от raulsaeed.
- Функционал и дизайн меню: TikTok You (Android).
