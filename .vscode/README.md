# VS Code Setup for Swift Development

This directory contains configuration files for Visual Studio Code to provide optimal Swift development experience.

## Files

- `settings.json`: VS Code settings specific to this project
- `launch.json`: Debug configurations
- `tasks.json`: Build and test tasks
- `extensions.json`: Recommended extensions for Swift development

## Required Extensions

The following extensions should be installed for the best Swift development experience:

1. **Swift Extension Pack** (sswg.swift-lang) - Main Swift support
2. **CodeLLDB** (vadimcn.vscode-lldb) - Debugging support
3. **Swift Development Environment** (vknabel.vscode-swift-development-environment) - Additional Swift tools
4. **Swift Format** (vknabel.vscode-swiftformat) - Code formatting
5. **SwiftLint** (vknabel.vscode-swiftlint) - Code linting
6. **Swift Test Explorer** (asuka.vscode-swift-test-explorer) - Test running support

To install the recommended extensions:
1. Open the Extensions view (⇧⌘X)
2. Type `@recommended` in the search box
3. Install all the recommended extensions

## Usage

- Build: ⇧⌘B or run the "Swift: Build" task
- Test: ⇧⌘D then select "Debug Tests" configuration
- Run: ⇧⌘D then select "Debug OCRExamples" configuration

## Troubleshooting

If you encounter issues with Swift support:

1. Ensure Xcode command-line tools are installed: `xcode-select --install`
2. Verify SourceKit-LSP path: `xcrun --find sourcekit-lsp`
3. If needed, update the path in settings.json
4. Restart VS Code to apply changes