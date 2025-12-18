# E2EE Chat App

A Flutter End-to-End Encrypted chat application with real-time messaging via Pusher.

## Features

- 🔐 AES-256 encryption (client-side)
- 💬 Real-time messaging via Pusher
- 👥 Multi-user chat rooms
- 🎨 Material Design 3 with dark mode

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── env_configs.dart       # Environment configuration
│   ├── network/
│   │   └── http_overrides.dart    # SSL/HTTP overrides
│   └── services/
│       └── encryption_services.dart
├── features/chat/
│   ├── data/
│   │   ├── datasources/pusher_services.dart
│   │   ├── models/message_model.dart
│   │   └── repositories/chat_repository_impl.dart
│   ├── domain/
│   │   ├── entities/message.dart
│   │   └── repositories/chat_repository.dart
│   └── presentation/
│       ├── bloc/
│       └── pages/
└── main.dart
```

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Environment

Create a `.env` file in the project root:

```env
PUSHER_APP_ID=your_app_id
PUSHER_KEY=your_key
PUSHER_SECRET=your_secret
PUSHER_CLUSTER=your_cluster
```

### 3. Run

```bash
flutter run
```

## How It Works

```
User A: "Hello" → Encrypt (AES-256) → Pusher → Decrypt → User B: "Hello"
```

- PIN derives the encryption key via PBKDF2
- Messages encrypted locally before transmission
- Only users with correct PIN can decrypt

## Usage

1. **Enter Username** → Choose your display name
2. **Create/Join Room** → Share room ID & PIN with others
3. **Chat** → Messages are E2E encrypted

## License

MIT
