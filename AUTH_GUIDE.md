# Руководство по авторизации

## Обзор

Приложение использует систему авторизации через WebSocket и Telegram бота согласно официальной документации API "Интересно и точка".

## Процесс авторизации

### Шаг 1: Создание анонимной сессии

При первом запуске приложение создает анонимную сессию:
```
GET /api/v1/auth/sessions/new
```

Ответ:
```json
{
  "id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "lifetime_minutes": 30,
  "created_at": "2023-10-27T10:00:00Z",
  "expires_at": "2023-10-27T10:30:00Z",
  "refresh_token": null,
  "auth": false
}
```

### Шаг 2: Генерация QR-кода

Приложение генерирует QR-код со ссылкой:
```
https://t.me/interesnoitochka_bot?start=auth_{session_id}
```

### Шаг 3: WebSocket подключение

Приложение подключается к WebSocket для ожидания токенов:
```
wss://interesnoitochka.ru/api/v1/ws/ws/session/{session_id}
```

### Шаг 4: Сканирование QR-кода

Пользователь сканирует QR-код в Telegram боте @interesnoitochka_bot

### Шаг 5: Получение токенов

После подтверждения в боте, приложение получает через WebSocket:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```

### Шаг 6: Сохранение токенов

Токены сохраняются в UserDefaults (в production рекомендуется Keychain)

## Альтернативный метод: Ручной ввод токенов

Для тестирования доступен ручной ввод токенов:

1. Нажмите "Ввести токен вручную"
2. Введите `access_token`
3. Введите `refresh_token`
4. Нажмите "Войти"

## Работа с API

После авторизации все запросы к API должны содержать заголовок:
```
Authorization: Bearer {access_token}
```

## Обновление токенов

Когда `access_token` истекает (ошибка 401), приложение автоматически обновляет его:

```
POST /api/v1/auth/jwt/refresh/new
Content-Type: application/x-www-form-urlencoded

token={refresh_token}
```

Ответ:
```json
{
  "access_token": "new_token...",
  "refresh_token": "new_refresh_token...",
  "token_type": "Bearer"
}
```

## Реализация в коде

### Файлы:

1. **AuthViewController.swift** - UI для авторизации с QR-кодом
2. **AuthWebSocketService.swift** - WebSocket клиент для получения токенов
3. **APIService.swift** - Методы для работы с сессиями и токенами
4. **AuthManager.swift** - Хранение и управление токенами

### Компоненты AuthViewController:

- QR-код с ссылкой на бота
- Статус подключения
- Индикатор загрузки
- Кнопка ручного ввода токенов

### Delegate методы AuthWebSocketDelegate:

```swift
func authWebSocketDidConnect()
func authWebSocketDidReceiveTokens(accessToken: String, refreshToken: String)
func authWebSocketDidFailWithError(_ error: Error)
```

## Тестирование

### Вариант 1: Telegram бот (рекомендуемый)

1. Запустите приложение
2. Отсканируйте QR-код в Telegram боте @interesnoitochka_bot
3. Подтвердите авторизацию в боте
4. Токены будут получены автоматически

### Вариант 2: Ручной ввод (для тестирования)

1. Получите токены другим способом (например, из веб-версии)
2. Нажмите "Ввести токен вручную"
3. Вставьте `access_token` и `refresh_token`
4. Войдите в приложение

## Troubleshooting

### Проблема: QR-код не генерируется
**Решение**: Проверьте, что сессия была успешно создана (смотрите консоль Xcode)

### Проблема: WebSocket не подключается
**Решение**: Проверьте интернет соединение и доступность сервера

### Проблема: Токены не приходят после сканирования
**Решение**: Убедитесь что:
- WebSocket подключен (статус "Отсканируйте QR-код в боте")
- Правильно отсканирован QR-код в боте @interesnoitochka_bot
- Подтверждена авторизация в боте

### Проблема: Ошибка 401 при запросах к API
**Решение**:
- Токены истекли - используйте refresh token
- Токены невалидны - авторизуйтесь заново

## Безопасность

⚠️ **Важно для production:**

1. Используйте Keychain вместо UserDefaults для хранения токенов
2. Реализуйте SSL pinning для защиты от MITM атак
3. Добавьте проверку истечения токенов
4. Реализуйте автоматическое обновление токенов при 401 ошибках
5. Добавьте лог-аут при критических ошибках авторизации

## Диаграмма потока авторизации

```
[Запуск приложения]
        ↓
[Проверка сохраненных токенов]
        ↓
   Токены есть? ─Yes→ [Переход к чатам]
        ↓ No
[Создание сессии: GET /auth/sessions/new]
        ↓
[Генерация QR-кода с session_id]
        ↓
[WebSocket подключение: wss://.../session/{id}]
        ↓
[Отображение QR-кода пользователю]
        ↓
[Ожидание сканирования в Telegram боте]
        ↓
[Подтверждение в боте]
        ↓
[Получение токенов через WebSocket]
        ↓
[Сохранение токенов]
        ↓
[Переход к чатам]
```

## API Endpoints

### Создание сессии
```
GET /api/v1/auth/sessions/new
Response: SessionResponse
```

### WebSocket для авторизации
```
WSS wss://interesnoitochka.ru/api/v1/ws/ws/session/{session_id}
Message: {"access_token": "...", "refresh_token": "..."}
```

### Обновление токена
```
POST /api/v1/auth/jwt/refresh/new
Content-Type: application/x-www-form-urlencoded
Body: token={refresh_token}
Response: TokenInfo
```

### Получение текущего пользователя
```
POST /api/v1/auth/jwt/you
Headers: Authorization: Bearer {access_token}
Response: User
```

## Дополнительная информация

Полная документация API: https://interesnoitochka.ru/api/v1/docs
