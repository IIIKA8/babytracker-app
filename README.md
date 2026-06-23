# Baby Tracker

Flutter-приложение для отслеживания режима малыша. Работает на **Android**, **iOS** и в **браузере** (Safari на iPhone).

---

## Развёртывание на своём GitHub (пошагово)

Инструкция для второго человека: свой аккаунт GitHub, свой (или общий) Firebase, приложение в браузере на iPhone.

### Шаг 1. Установить на ПК

| Программа | Ссылка |
|-----------|--------|
| Git (с Git LFS) | https://git-scm.com |
| Flutter (stable) | https://docs.flutter.dev/get-started/install |
| Node.js | https://nodejs.org |
| GitHub CLI | https://cli.github.com |

Проверка:

```powershell
git --version
git lfs version
flutter doctor
gh --version
```

### Шаг 2. Скачать проект

**Вариант А** — скопировать с флешки / архива / от коллеги (папка с проектом).

**Вариант Б** — клонировать исходный репозиторий:

```powershell
cd C:\Projects
git clone https://github.com/IIIKA8/babytracker-app.git
cd babytracker-app
```

> Клонируйте в папку **без кириллицы** в пути (`C:\Projects\`), иначе сборка web на Windows может падать.

```powershell
.\tool\setup.ps1
```

### Шаг 3. Войти в свой GitHub

```powershell
gh auth login
```

Выберите: GitHub.com → HTTPS → Login with browser.

### Шаг 4. Создать свой репозиторий и залить код

Из папки проекта:

```powershell
.\tool\init_own_github.ps1 -RepoName babytracker-app
```

Для **публичного** репозитория (если нужен GitHub Pages):

```powershell
.\tool\init_own_github.ps1 -RepoName babytracker-app -Public
```

Скрипт создаст `https://github.com/ВАШ_ЛОГИН/babytracker-app` и запушит код.

**Вручную** (если без скрипта):

```powershell
gh repo create ВАШ_ЛОГИН/babytracker-app --private --source=. --remote=origin --push
```

### Шаг 5. Настроить Firebase

**Вариант А — свой Firebase-проект** (рекомендуется, свои данные):

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Выберите новый проект в Firebase Console. Обновятся `lib/firebase_options.dart`, `.firebaserc`, `firebase.json`.

В [Firebase Console](https://console.firebase.google.com/) → **Authentication → Settings → Authorized domains** добавьте домен вида `ваш-project-id.web.app`.

**Вариант Б — общий Firebase** (тот же проект, что у коллеги):

- Файл `.firebaserc` уже содержит `babytracker-9474d`
- Нужен `FIREBASE_TOKEN` от владельца Firebase-проекта (`firebase login:ci` на его аккаунте)

### Шаг 6. Секрет для GitHub Actions

На **своём** репозитории:

```powershell
firebase login:ci
```

Скопируйте токен. Затем в браузере:

`https://github.com/ВАШ_ЛОГИН/babytracker-app` → **Settings → Secrets and variables → Actions → New repository secret**

| Имя | Значение |
|-----|----------|
| `FIREBASE_TOKEN` | токен из `firebase login:ci` |

### Шаг 7. Первый деплой

1. GitHub → ваш репозиторий → вкладка **Actions**
2. **Deploy Web to Firebase Hosting** → **Run workflow** → **Run workflow**
3. Дождитесь зелёной галочки (~3 мин)

### Шаг 8. Открыть на iPhone

В Safari откройте:

```
https://<ваш-project-id>.web.app
```

ID проекта смотрите в `.firebaserc` (поле `default`).

Закрепить на главный экран: **Поделиться → На экран «Домой»**.

---

## Ежедневная работа (после настройки)

```powershell
cd C:\Projects\babytracker-app
git pull
# ... правки в коде ...
flutter run -d chrome          # проверка в браузере
git add .
git commit -m "описание"
git push origin main           # автодеплой на Firebase
```

Через ~3 минуты сайт обновится на iPhone.

---

## Альтернатива: GitHub Pages (только публичный репозиторий)

1. Репозиторий **public**: `.\tool\init_own_github.ps1 -Public`
2. **Settings → Pages → Source: GitHub Actions**
3. **Actions → Deploy Web to GitHub Pages → Run workflow**
4. Сайт: `https://ВАШ_ЛОГИН.github.io/babytracker-app/`
5. Домен `ВАШ_ЛОГИН.github.io` добавьте в Firebase Authorized domains

---

## Локальный запуск

```powershell
flutter run -d chrome
flutter run -d android
.\tool\build_web.ps1    # если путь к проекту с кириллицей
```

---

## Скрипты в `tool/`

| Файл | Назначение |
|------|------------|
| `setup.ps1` | После clone: LFS + `flutter pub get` |
| `init_own_github.ps1` | Создать репозиторий на своём GitHub и запушить |
| `build_web.ps1` | Сборка web (обход кириллицы в пути Windows) |

---

## Workflows (Actions)

| Workflow | Когда запускается |
|----------|-------------------|
| Deploy Web to Firebase Hosting | Каждый push в `main` (нужен `FIREBASE_TOKEN`) |
| Deploy Web to GitHub Pages | Вручную (публичный репо) |
| iOS unsigned IPA | Вручную → артефакт для Sideloadly |
| iOS Simulator build | PR / вручную |
