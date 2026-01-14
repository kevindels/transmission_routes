# Contributing to Transmission Routes

First off, thank you for considering contributing to Transmission Routes! It's people like you that make this app better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots, logs)
- **Describe the behavior you observed and what you expected**
- **Include details about your environment** (Flutter version, OS, device)

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) when creating issues.

### Suggesting Features

Feature suggestions are welcome! Before creating a feature request:

- **Check if the feature has already been suggested**
- **Provide a clear and detailed explanation** of the feature
- **Explain why this feature would be useful** to most users
- **Include examples** of how the feature would work

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding guidelines** described below
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Ensure CI/CD passes** all checks
6. **Write clear commit messages** following our guidelines
7. **Submit a pull request** with a comprehensive description

## Development Setup

1. **Clone your fork:**
```bash
git clone https://github.com/YOUR_USERNAME/transmission_routes.git
cd transmission_routes
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure the server:**
Edit `lib/config/api_config.dart` with your development server URL:
```dart
static const String baseUrl = 'http://YOUR_DEV_SERVER:3000/api';
static const String wsUrl = 'http://YOUR_DEV_SERVER:3000';
```

4. **Run the app:**
```bash
flutter run
```

5. **Run tests:**
```bash
flutter test
```

## Coding Guidelines

### General Principles

- **Follow Dart best practices** and the [Effective Dart guide](https://dart.dev/guides/language/effective-dart)
- **Use GetX patterns** for state management, dependency injection, and routing
- **Keep code DRY** (Don't Repeat Yourself)
- **Write self-documenting code** with clear naming
- **Add comments** for complex logic only

### Architecture

This project follows **GetX MVC architecture**:

```
lib/
├── models/          # Data models
├── services/        # Business logic and external APIs
├── controllers/     # UI logic and state management
├── views/           # UI screens
├── widgets/         # Reusable UI components
├── routes/          # Navigation routes
├── bindings/        # Dependency injection
├── config/          # Configuration files
└── utils/           # Helper functions
```

### Code Style

- **Naming conventions:**
  - Classes: `PascalCase` (e.g., `StreamingController`)
  - Files: `snake_case` (e.g., `streaming_controller.dart`)
  - Variables/Functions: `camelCase` (e.g., `startStreaming()`)
  - Constants: `camelCase` with `static const` (e.g., `maxViewers`)

- **File organization:**
  - One class per file
  - Related functionality grouped together
  - Imports organized: Dart SDK → Flutter → Third-party → Local

- **GetX patterns:**
  - Controllers should extend `GetxController`
  - Use `.obs` for reactive variables
  - Use `Obx()` or `GetBuilder()` for UI updates
  - Inject dependencies via bindings

### Testing

- Write **unit tests** for services and controllers
- Write **widget tests** for complex UI components
- Ensure **test coverage** for critical functionality
- Mock external dependencies

## Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system or dependency changes
- **ci**: CI/CD changes
- **chore**: Other changes that don't modify src or test files

### Examples

```
feat(streaming): add viewer count display

Implement real-time viewer count in streaming view using WebSocket events.

Closes #123
```

```
fix(gps): correct distance calculation

Fixed haversine formula implementation that was causing incorrect distance measurements.
```

```
docs(readme): update installation instructions

Added troubleshooting section for common setup issues.
```

## Questions?

Feel free to open an issue with the `question` label, or contact the maintainers directly.

Thank you for contributing! 🎉
