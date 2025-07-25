# SSH Client - Flutter

A modern, feature-rich SSH client built with Flutter that serves as the foundation for managing personal infrastructure labs and remote servers.

## Vision

This SSH client is the first stepping stone toward building a comprehensive personal infrastructure management system. While currently focused on providing a clean, efficient SSH interface, it's designed with the future goal of managing:

- **Raspberry Pi Infrastructure Labs** - Remote management of Pi-based services
- **CI/CD Pipeline Control** - Interface for Jenkins and build systems
- **IoT Device Management** - Control and monitor edge devices
- **Development Environment Access** - Quick access to development servers
- **Personal Cloud Services** - Manage self-hosted applications

## Features

### Current Implementation
- **Persistent Shell Sessions** - Commands like `cd` maintain state across executions
- **Real-time Terminal Output** - Live command execution with proper output streaming
- **Connection Management** - Save and quickly reconnect to frequently used servers
- **Modern UI** - Clean, compact interface optimized for productivity
- **Cross-platform Support** - Runs on Linux, Windows, macOS, Android, and iOS
- **Secure Authentication** - Password-based authentication with planned key support

### Architecture Highlights
- **Scalable Structure** - Organized into features, services, and core modules
- **State Management** - GetX for reactive state management
- **Persistent Storage** - SharedPreferences for connection history
- **Comprehensive Logging** - Built-in logging service for debugging
- **Service-oriented Design** - Modular services for SSH, storage, and logging

## Project Structure

```
lib/
├── core/
│   ├── constants/           # App-wide constants and configurations
│   ├── services/           # Core services (SSH, Storage, Logging)
│   └── themes/             # UI themes and styling
├── features/
│   └── ssh/               # SSH feature module
│       ├── controllers/    # GetX controllers for state management
│       ├── views/         # Screen implementations
│       └── widgets/       # Feature-specific widgets
└── shared/
    └── widgets/           # Reusable UI components
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ssh_client
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For desktop (Linux/Windows/macOS)
   flutter run -d linux
   flutter run -d windows
   flutter run -d macos
   
   # For mobile
   flutter run -d android
   flutter run -d ios
   ```

### Configuration
The app automatically saves your last used connection details and maintains a history of saved connections for quick access.

## Usage

### Connecting to a Server
1. Enter your server details (IP/hostname, username, password)
2. Click "Connect" to establish SSH session
3. Use the terminal interface to execute commands
4. Connection details are automatically saved for future use

### Terminal Operations
- **Persistent Sessions**: Directory changes (`cd`) and environment variables persist
- **Command History**: Previous commands are logged and can be reviewed
- **Real-time Output**: See command results as they execute
- **Error Handling**: Clear error messages for connection and execution issues

### Managing Connections
- **Save Connections**: Frequently used servers are automatically saved
- **Quick Connect**: Select from saved connections for instant access
- **Connection History**: Review and manage your connection history


## Future Roadmap

### Near-term Enhancements
- [ ] **SSH Key Authentication** - Private key support for enhanced security
- [ ] **File Transfer** - SFTP integration for file upload/download
- [ ] **Port Forwarding** - Local and remote port forwarding support
- [ ] **Session Tabs** - Multiple concurrent SSH sessions
- [ ] **Command Snippets** - Save and execute common command sequences

### Infrastructure Lab Integration
- [ ] **Raspberry Pi Management** - Specialized tools for Pi administration
- [ ] **Service Dashboard** - Monitor running services (Jenkins, Grafana, etc.)
- [ ] **Automated Deployment** - One-click deployment commands
- [ ] **System Monitoring** - Real-time system metrics and alerts
- [ ] **Container Management** - Docker/Podman container control

### Advanced Features
- [ ] **Mobile Background Sync** - Automated file upload when on home network
- [ ] **CI/CD Integration** - Trigger builds and monitor pipeline status
- [ ] **IoT Device Control** - Manage connected devices and sensors
- [ ] **Encrypted Messaging** - Secure communication channel
- [ ] **Local AI Integration** - Interface for self-hosted LLM services

## Use Cases

### Personal Infrastructure Management
Perfect for managing home lab setups, Raspberry Pi clusters, and personal servers. Ideal for developers building their own infrastructure learning environments.

### Development Workflow
Streamline access to development servers, staging environments, and production systems. Quick deployment and debugging capabilities.

### IoT and Edge Computing
Manage edge devices, update configurations, and monitor distributed systems from a single, mobile-friendly interface.

### Learning and Experimentation
Ideal platform for learning system administration, DevOps practices, and infrastructure management in a hands-on environment.

## Contributing

Contributions are welcome! This project is designed to grow into a comprehensive infrastructure management tool. Areas where contributions are particularly valuable:

- **Security Features** - SSH key management, secure storage
- **Protocol Support** - Additional protocols (Telnet, Serial, etc.)
- **UI/UX Improvements** - Enhanced terminal experience
- **Platform Optimization** - Mobile-specific features
- **Documentation** - Usage guides and tutorials
