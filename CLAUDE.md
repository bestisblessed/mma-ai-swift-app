# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands
- Run Flask server: `python app.py`
- Update data: `./update_data.sh` 
- Deploy server: `./run.sh`

## Code Style Guidelines
- Swift: Follow SwiftUI conventions with structured view hierarchy
- Python: PEP 8 style with proper error handling using try/except
- Imports: Group by standard library, third-party, then local modules
- Naming: camelCase for Swift variables/functions, snake_case for Python
- Error handling: Use optional chaining in Swift, explicit try/except in Python
- Type safety: Use strong typing with explicit optionals in Swift
- Documentation: Add comments for complex logic, data processing functions
- Logging: Use Python's logging module for backend, print statements for Swift debugging
- File organization: Keep related functionality in same file, following MVVM pattern